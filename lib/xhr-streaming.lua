local function handler(self, options, sid)
  self:handle_xhr_cors()
  self:handle_balancer_cookie()
  local content = ('h'):rep(2048) .. '\n'
  self:send(200, content, {
    ['Content-Type'] = 'application/javascript; charset=UTF-8'
  }, false)
  self.protocol = 'xhr-streaming'
  self.curr_size, self.max_size = 0, options.response_limit
  self.send_frame = function (self, payload, continue)
    return self:write_frame(payload .. '\n', continue)
  end
  self:create_session(self.req, self, sid, options)
end

return {
  POST = handler
}
