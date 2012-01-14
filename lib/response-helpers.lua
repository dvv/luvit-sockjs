local Response = require('response')

function Response.prototype:handle_xhr_cors()
  local origin = self.req.headers['origin'] or '*'
  self:set_header('Access-Control-Allow-Origin', origin)
  local headers = self.req.headers['access-control-request-headers']
  if headers then
    self:set_header('Access-Control-Allow-Headers', headers)
  end
  self:set_header('Access-Control-Allow-Credentials', 'true')
end

function Response.prototype:handle_balancer_cookie()
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
  self:add_header('Set-Cookie', 'JSESSIONID=' .. jsid .. '; path=/')
end

function Response.prototype:write_frame(payload, callback)
  if self.max_size then
    self.curr_size = self.curr_size + #payload
  end
  self:write(payload, function (err)
    p('WR', self.req.url, self.curr_size, '/', self.max_size)
    if self.max_size and self.curr_size >= self.max_size then
      p('FIN?', self.req.url)
      --[[self:finish(function()
        p('FIN!', self.req.url)
        if callback then callback(err) ; return end
      end)]]--
      self:finish()
    end
    if callback then callback() end
  end)
end

return Response
