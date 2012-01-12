local function handler(self, options, sid)
  self:handle_xhr_cors()
  self:handle_balancer_cookie()
  self.auto_chunked = false
  self:send(200, nil, {
    ['Content-Type'] = 'application/javascript; charset=UTF-8'
  }, false)
  self.protocol = 'xhr'
  self.curr_size, self.max_size = 0, 1
  self.send_frame = function (self, payload, callback)
    return self:write_frame(payload .. '\n', callback)
  end
  self:create_session(self.req, self, sid, options)
end

return {
  POST = handler
}
