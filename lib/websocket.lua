--
-- WebSocket transport
--

local Table = require('table')
local JSON = require('json')

local WebSocket = require('websocket')

local function verify_origin(origin, origins)
  return true
end

local function handler(self, options)

  -- defaults
  if not options then options = { } end

  WebSocket.handler(self.req, self, function ()

    self.protocol = 'websocket'
    self.curr_size, self.max_size = 0, options.response_limit

    -- setup sender
    self.send_frame = self.send
    self.req:once('close', function (...)
      self:finish()
    end)

    -- setup receiver
    self.req:on('message', function (raw)
      local status, message = pcall(JSON.parse, raw)
      if not status then
        self:finish()
      else
        self.session:onmessage(message)
      end
    end)

    -- and register connection
    self:create_session(self.req, self, nil, options)

  end)

end

-- module
return {
  GET = handler
}
