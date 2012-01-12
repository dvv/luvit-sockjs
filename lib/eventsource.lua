local escape_for_eventsource1
escape_for_eventsource1 = function(str)
  local s = ''
  for i = 1, #str do
    local c = str:sub(i, i)
    print('C', c, c == '\r')
    if c == '%' then
      c = '%25'
    end
    if c == '\0' then
      c = '%00'
    end
    if c == '\r' then
      c = '%0A'
    end
    if c == '\n' then
      c = '%0D'
    end
    s = s .. c
  end
  print(str, '->', s)
  return s
end

local function handler(self, options, sid)
  self:handle_balancer_cookie()
  self:send(200, '\r\n', {
    ['Content-Type'] = 'text/event-stream; charset=UTF-8',
    ['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
  }, false)
  self.protocol = 'eventsource'
  self.curr_size, self.max_size = 0, options.response_limit
  self.send_frame = function (self, payload, continue)
    return self:write_frame('data: ' .. payload .. '\r\n\r\n', continue)
  end
  self:create_session(self.req, self, sid, options)
end

return {
  GET = handler
}
