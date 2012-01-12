local JSON = require('json')

local htmlfile_template = [[<!doctype html>
<html><head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head><body><h2>Don't panic!</h2>
  <script>
    document.domain = document.domain;
    var c = parent.{{ callback }};
    c.start();
    function p(d) {c.message(d);};
    window.onload = function() {c.stop();};
  </script>
]]

htmlfile_template = htmlfile_template .. (' '):rep(1024 - #htmlfile_template + 14) .. '\r\n\r\n'

local function handler(self, options, sid)
  self:handle_balancer_cookie()
  local query = self.req.uri.query
  local callback = query.c or query.callback
  if not callback then
    self:fail('"callback" parameter required')
    return
  end
  local content = htmlfile_template:gsub('{{ callback }}', callback)
  self:send(200, content, {
    ['Content-Type'] = 'text/html; charset=UTF-8',
    ['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0'
  }, false)
  self.protocol = 'htmlfile'
  self.curr_size, self.max_size = 0, options.response_limit
  self.send_frame = function (self, payload, callback)
    return self:write_frame('<script>\np(' .. JSON.stringify(payload) .. ');\n</script>\r\n', callback)
  end
  self:create_session(self.req, self, sid, options)
end

return {
  GET = handler
}
