local Table = require('table')
local Emitter = require('core').Emitter
local Timer = require('timer')
local JSON = require('json')
local uuid = require('uuid')

local sessions = { }

_G.s = function()
  return sessions
end

local Session = Emitter:extend()

function Session.get(sid)
  return sessions[sid]
end

function Session.get_or_create(sid, options)
  local session = Session.get(sid)
  if not session then
    session = Session:new(sid, options)
  end
  return session
end

function Session.closing_frame(status, reason)
  return 'c' .. JSON.stringify({
    status,
    reason
  })
end

Session.CONNECTING = 0
Session.OPEN = 1
Session.CLOSING = 2
Session.CLOSED = 3

function Session:initialize(sid, options)
  -- FIXME: should get rid
  self.options = options
  self.sid = sid
  self.heartbeat_delay = options.heartbeat_delay
  self.disconnect_delay = options.disconnect_delay
  self.prefix = options.prefix
  self.id = uuid()
  self.send_buffer = { }
  self.ready_state = Session.CONNECTING
  if self.sid then
    sessions[self.sid] = self
  end
  self.to_tref = Timer.setTimeout(self.disconnect_delay, self.ontimeout, self)
  self.emit_connection_event = function()
    self.emit_connection_event = nil
    options.onopen(self)
  end
end

function Session:bind(req, conn)
  --p('BIND', self.sid, self.ready_state, self.conn ~= nil)
  if self.conn then
    conn:send_frame(Session.closing_frame(2010, 'Another connection still open'))
    conn:finish()
    --self:unbind()
    return
  end
  if self.ready_state == Session.CLOSING then
    --p('BINDING CLOSING', self.close_frame)
    conn:send_frame(self.close_frame)
    conn:finish()
    --self:unbind()
    return
  end
  self.conn = conn
  conn.session = self
  conn:once('end', function()
    --p('CONNENDED!')
    self:unbind()
  end)
  req:once('end', function()
    --p('REQENDED!')
    --self:unbind()
    --conn:finish()
  end)
  req:once('error', function()
    --p('REQERRORED!')
    conn:finish()
    --self:unbind()
  end)
  self.req = req
  if self.ready_state == Session.CONNECTING then
    self.conn:send_frame('o')
    self.ready_state = Session.OPEN
    Timer.setTimeout(0, self.emit_connection_event)
  end
  if self.to_tref then
    Timer.clearTimer(self.to_tref)
    self.to_tref = nil
  end
  self:flush()
end

function Session:unbind(force)
  --p('UNBIND', self.sid)
  if self.conn then
    self.conn.session = nil
    self.conn = nil
  end
  if self.to_tref then
    Timer.clearTimer(self.to_tref)
    self.to_tref = nil
  end
  if force then
    self:ontimeout()
  else
    self.to_tref = Timer.setTimeout(self.disconnect_delay, self.ontimeout, self)
  end
end

function Session:ontimeout()
  if self.to_tref then
    Timer.clearTimer(self.to_tref)
    self.to_tref = nil
  end
  if self.ready_state ~= Session.CONNECTING and self.ready_state ~= Session.OPEN and self.ready_state ~= Session.CLOSING then
    error('INVALID_STATE_ERR')
  end
  if self.conn then
    error('RECV_STILL_THERE')
  end
  self.ready_state = Session.CLOSED
  --self:emit('close')
  if self.sid then
    sessions[self.sid] = nil
    self.sid = nil
  end
end

function Session:onmessage(payload)
  if self.ready_state == Session.OPEN then
    --self:emit('message', payload)
    self.options.onmessage(self, payload)
  end
end

function Session:flush()
  if not self.conn then return end
  if #self.send_buffer > 0 then
    local messages = self.send_buffer
    self.send_buffer = { }
    local quoted = (function()
      local _accum_0 = { }
      local _len_0 = 0
      local _list_0 = messages
      for _index_0 = 1, #_list_0 do
        local m = _list_0[_index_0]
        _len_0 = _len_0 + 1
        _accum_0[_len_0] = JSON.stringify(m)
      end
      return _accum_0
    end)()
    self.conn:send_frame('a' .. '[' .. Table.concat(quoted, ',') .. ']')
  else
    if self.to_tref then
      Timer.clearTimer(self.to_tref)
      self.to_tref = nil
    end
    local heartbeat
    heartbeat = function ()
      if self.conn then
        self.conn:send_frame('h')
        self.to_tref = Timer.setTimeout(self.heartbeat_delay, heartbeat)
      else
        self.to_tref = nil
      end
    end
    self.to_tref = Timer.setTimeout(self.heartbeat_delay, heartbeat)
  end
end

function Session:close(status, reason)
  if status == nil then
    status = 1000
  end
  if reason == nil then
    reason = 'Normal closure'
  end
  if self.ready_state ~= Session.OPEN then
    return false
  end
  self.ready_state = Session.CLOSING
  self.close_frame = Session.closing_frame(status, reason)
  if self.conn then
    self.conn:send_frame(self.close_frame, function()
      if self.conn then
        self.conn:finish()
      end
    end)
  end
end

function Session:send(payload)
  if self.ready_state ~= Session.OPEN then
    return false
  end
  Table.insert(self.send_buffer, type(payload) == 'table' and Table.concat(payload, ',') or tostring(payload))
  Timer.setTimeout(0, function()
    return self:flush()
  end)
  return true
end

-- module
return Session
