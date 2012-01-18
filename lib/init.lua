local Table = require('table')
local Stack = require('stack')

-- augment response object with some helpers
require('./response-helpers')

local transport_handlers = {
  xhr_send = require('./xhr-jsonp-send'),
  jsonp_send = require('./xhr-jsonp-send'),
  xhr = require('./xhr-polling'),
  jsonp = require('./jsonp-polling'),
  xhr_streaming = require('./xhr-streaming'),
  websocket = require('./websocket'),
  htmlfile = require('./htmlfile'),
  eventsource = require('./eventsource')
}

local other_handlers = {
  options = require('./options'),
  info_test = require('./info-test'),
  iframe = require('./iframe')
}

local Session = require('./session')

local servers = { }

local function SockJS_handler(options)

  -- defaults
  assert(options and options.root)
  servers[options.root] = options
  for k, v in pairs({
    sockjs_url = '/static/sockjs.js',
    heartbeat_delay = 25000,
    disconnect_delay = 5000,
    response_limit = 128 * 1024,
    origins = {
      '*:*'
    },
    disabled_transports = { },
    cache_age = 365 * 24 * 60 * 60,
    --new = require('websocket/lib/connection').new,
    onopen = function (self) end,
    onclose = function (self) end,
    onerror = function (self, error) end,
    onmessage = function (self, message) end,
  }) do if options[k] == nil then options[k] = v end
  end

  -- compose raw websocket handler
  local raw_websocket
  if not options.disabled_transports.websocket then
    raw_websocket = require('websocket')(options)
  end

  -- handler
  return function (req, res, nxt)

    res.req = req

    req:once('error', function(err)
      debug('REQ-ERROR', err)
      return req:close()
    end)
    res:once('error', function(err)
      debug('RES-ERROR', err)
      res.closed = true
      return res:close()
    end)

    res.get_session = function(self, sid)
      return Session.get(sid)
    end

    res.create_session = function(self, req, conn, sid, options)
      local session = Session.get_or_create(sid, options)
      return session:bind(req, conn)
    end

    -- get request path
    local path = req.uri.pathname
    if path:sub(-1, -1) == '/' then path = path:sub(1, -2) end

    -- handle root
    --if req.url == '' or req.url == '/' then
    if path == '' then
      if req.method == 'GET' then
        res:send(200, 'Welcome to SockJS!\n', {
          ['Content-Type'] = 'text/plain; charset=UTF-8'
        })
        return
      end
    else
      if path == '/info' then
        local handler = other_handlers.info_test[req.method]
        if not handler then
          res:send(405)
        else
          handler(res, options)
        end
        return
      elseif path == '/websocket' then
        if raw_websocket then
          raw_websocket(req, res, function ()
            res:serve_not_found()
          end)
          return
        end
      else
        if path:match('^/iframe[0-9-.a-z_]*%.html$') then
          local handler = other_handlers.iframe[req.method]
          if handler then
            handler(res, options)
            return
          end
        else
          local sid, transport = path:match('^/[^./]+/([^./]+)/([a-z_]+)$')
          if sid then
            if req.method == 'OPTIONS' then
              other_handlers.options(res, options)
            else
              -- ignore disabled transports
              for t, _ in pairs(options.disabled_transports) do
                if t == transport then
                  res:serve_not_found()
                  return
                end
              end
              local handler = transport_handlers[transport]
              if handler then
                handler = handler[req.method]
                if not handler then
                  res.auto_content_type = false
                  local allowed_verbs = { }
                  for k, _ in pairs(transport_handlers[transport]) do
                    Table.insert(allowed_verbs, k)
                  end
                  res:send(405, nil, {
                    ['Allow'] = Table.concat(allowed_verbs, ', '),
                  })
                  return
                end
                handler(res, options, sid, transport)
              end
            end
            return
          end
        end
      end
    end
    res:serve_not_found()
  end

end

-- module
return SockJS_handler
