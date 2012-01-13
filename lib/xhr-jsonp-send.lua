local Table = require('table')
local JSON = require('json')
local parse_query = require('querystring').parse

local allowed_content_types = {
  xhr_send = {
    ['application/json'] = JSON.parse,
    ['text/plain'] = JSON.parse,
    ['application/xml'] = JSON.parse,
    ['text/xml'] = JSON.parse,
    ['T'] = JSON.parse,
    [''] = JSON.parse
  },
  jsonp_send = {
    ['application/x-www-form-urlencoded'] = parse_query,
    ['text/plain'] = true,
    [''] = true
  }
}

local function handler(self, options, sid, transport)
  local xhr = transport == 'xhr_send'
  if xhr then self:handle_xhr_cors() end
  self:handle_balancer_cookie()
  self.auto_chunked = false
  local ctype = self.req.headers['content-type'] or ''
  ctype = ctype:match('[^;]*')
  local decoder = allowed_content_types[transport][ctype]
  if not decoder then
    self:fail('Payload expected.')
    return
  end
  local session = self:get_session(sid)
  if not session then
    self:serve_not_found()
    return
  end
  local data = { }
  self.req:on('data', function(chunk)
    Table.insert(data, chunk)
  end)
  self.req:on('end', function()
    data = Table.concat(data)
    if data == '' then
      self:fail('Payload expected.')
      return
    end
    if not xhr then
      if decoder ~= true then
        data = decoder(data).d or ''
      end
      if data == '' then
        self:fail('Payload expected.')
        return
      end
    end
    local status, messages = pcall(JSON.parse, data)
    if not status then
      self:fail('Broken JSON encoding.')
      return
    end
    -- let only array-like messages
    if type(messages) ~= 'table' then
      self:fail('Payload expected.')
      return
    end
    --
    for _, message in ipairs(messages) do
      session:onmessage(message)
    end
    if xhr then
      self:send(204, nil, {
        ['Content-Type'] = 'text/plain; charset=UTF-8',
      })
    else
      self.auto_content_type = false
      self:send(200, 'ok', {
        ['Content-Type'] = 'text/plain; charset=UTF-8',
        ['Content-Length'] = 2,
      })
    end
  end)
end

return {
  POST = handler
}
