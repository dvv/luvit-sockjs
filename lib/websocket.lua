--
-- WebSocket transport
--

local Table = require('table')
local WebSocket_Hixie76 = require('websocket/lib/hixie76')
local WebSocket_Hybi10 = require('websocket/lib/hybi10')

local function verify_origin(origin, origins)
  return true
end

local function handler(self, options)

  -- defaults
  if not options then options = { } end

  -- turn chunking mode off
  self.auto_chunked = false

  -- request sanity check
  if (self.req.headers.upgrade or ''):lower() ~= 'websocket' then
    return self:send(400, 'Can "Upgrade" only to "WebSocket".')
  end
  if not (',' .. (self.req.headers.connection or ''):lower() .. ','):match('[^%w]+upgrade[^%w]+') then
    return self:send(400, 'Bad Request')
  end
  local origin = self.req.headers.origin
  if not verify_origin(origin, options.origins) then
    return self:send(401, 'Unauthorized')
  end

  -- guess the protocol
  local location = origin and origin:sub(1, 5) == 'https' and 'wss' or 'ws'
  location = location .. '://' .. self.req.headers.host .. self.req.url
  -- determine protocol version
  local ver = self.req.headers['sec-websocket-version']
  local shaker = WebSocket_Hixie76
  if ver == '7' or ver == '8' or ver == '13' then
    shaker = WebSocket_Hybi10
  end

  -- disable buffering
  self:nodelay(true)

  self.protocol = 'websocket'
  self.curr_size, self.max_size = 0, options.response_limit

  -- handshake...
  shaker.handshake(self, origin, location, function ()
    -- setup sender
    self.send_frame = self.send
    -- and register connection
    self:create_session(self.req, self, nil, options)
  end)

end

-- module
return {
  GET = handler
}
