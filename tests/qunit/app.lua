#!/usr/bin/env luvit

process.env.DEBUG = '1'

-- create application
local app = require('app').new()

app:mount('/echo', require('sockjs')({
  root = 'WS',
  response_limit = 4096,
  cookie_needed = true,
  sockjs_url = '/sockjs.js',
  onopen = function (conn)
    --p('OPEN', conn)
  end,
  onclose = function (conn)
    --p('CLOSE', conn)
  end,
  onerror = function (conn, error)
    --p('ERROR', conn, error)
  end,
  onmessage = function (conn, message)
    p('<<<', message)
    -- repeater
    conn:send(message)
    p('>>>', message)
    -- close if 'quit' is got
    if message == 'quit' then
      conn:close(1002, 'Forced closure')
    end
  end,
}))

app:mount('/disabled_websocket_echo', require('sockjs')({
  root = 'WS1',
  response_limit = 4096,
  cookie_needed = true,
  sockjs_url = '/sockjs.js',
  disabled_transports = { websocket = true },
  onopen = function (conn)
    --p('OPEN', conn)
  end,
  onclose = function (conn)
    --p('CLOSE', conn)
  end,
  onerror = function (conn, error)
    --p('ERROR', conn, error)
  end,
  onmessage = function (conn, message)
    p('<<<', message)
    -- repeater
    conn:send(message)
    p('>>>', message)
    -- close if 'quit' is got
    --[[if message == 'quit' then
      conn:close(1002, 'Forced closure')
    end]]--
  end,
}))

app:mount('/close', require('sockjs')({
  root = 'WS2',
  response_limit = 4096,
  cookie_needed = true,
  sockjs_url = '/sockjs.js',
  onopen = function (conn)
    p('/CLOSE\\', conn.sid, conn.id)
    conn:close(3000, 'Go away!')
  end,
}))

app:mount('/', 'static', {
  directory = __dirname
})

-- run server
app:run(8081, '0.0.0.0')
