local Response = require('http').Response

function Response:handle_xhr_cors()
  local origin = self.req.headers['origin'] or '*'
  self:setHeader('Access-Control-Allow-Origin', origin)
  local headers = self.req.headers['access-control-request-headers']
  if headers then
    self:setHeader('Access-Control-Allow-Headers', headers)
  end
  self:setHeader('Access-Control-Allow-Credentials', 'true')
end

function Response:handle_balancer_cookie()
  if not self.req.cookies then
    self.req.cookies = { }
    if self.req.headers.cookie then
      for cookie in self.req.headers.cookie:gmatch('[^;]+') do
        local name, value = cookie:match('%s*([^=%s]-)%s*=%s*([^%s]*)')
        if name and value then
          self.req.cookies[name] = value
        end
      end
    end
  end
  local jsid = self.req.cookies['JSESSIONID'] or 'dummy'
  self:addHeader('Set-Cookie', 'JSESSIONID=' .. jsid .. '; path=/')
end

function Response:write_frame(payload, callback)
  if self.max_size then
    self.curr_size = self.curr_size + #payload
  end
  self:write(payload, function (err)
    if self.max_size and self.curr_size >= self.max_size then
      self:finish()
    end
    if callback then callback() end
  end)
end

return Response
