#!/usr/bin/env luvit

process.env.DEBUG = '1'

-- create application
local app = require('app').new()
local Connection = require('websocket/lib/connection')

app:mount('/echo', require('sockjs')({
  root = 'WS',
  new = Connection.new,
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
  new = Connection.new,
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
  new = Connection.new,
  response_limit = 4096,
  cookie_needed = true,
  sockjs_url = '/sockjs.js',
  onopen = function (conn)
    p('/CLOSE\\', conn.sid, conn.id)
    conn:close(3000, 'Go away!')
  end,
}))

app:mount('/amplify', require('sockjs')({
  root = 'WS3',
  new = Connection.new,
  response_limit = 4096,
  cookie_needed = true,
  sockjs_url = '/sockjs.js',
  onopen = function (conn)
    --p('OPEN', conn)
  end,
  onclose = function (conn)
    --p('CLOSE', conn)
  end,
  onmessage = function (conn, message)
    local Math = require('math')
    local status, n = pcall(Math.floor, tonumber(message, 10))
    if not status then
      error(message)
    end
    n = (n > 0 and n < 19) and n or 1
    conn:send(('x'):rep(Math.pow(2, n)))
  end,
}))

local broadcast = { }
app:mount('/broadcast', require('sockjs')({
  root = 'WS4',
  new = Connection.new,
  response_limit = 4096,
  cookie_needed = true,
  sockjs_url = '/sockjs.js',
  onopen = function (conn)
    broadcast[conn.id] = conn
  end,
  onclose = function (conn)
    broadcast[conn.id] = nil
  end,
  onmessage = function (conn, message)
    for k, v in pairs(broadcast) do
      v:send(message)
    end
  end,
}))

app:mount('/', 'static', {
  directory = __dirname
})

-- run server
app:run(8081, '0.0.0.0')
