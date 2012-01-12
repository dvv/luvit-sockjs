local OS = require('os')
local date, time = OS.date, OS.time

local iframe_template = [[<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <script>
    document.domain = document.domain;
    _sockjs_onload = function(){SockJS.bootstrap_iframe();};
  </script>
  <script src="{{ sockjs_url }}"></script>
</head>
<body>
  <h2>Don't panic!</h2>
  <p>This is a SockJS hidden iframe. It's used for cross domain magic.</p>
</body>
</html>
]]

local function handler(self, options)
    local content = iframe_template:gsub('{{ sockjs_url }}', options.sockjs_url)
    local etag = tostring(#content)
    if self.req.headers['if-none-match'] == etag then
      return self:send(304)
    end
    self:send(200, content, {
      ['Content-Type'] = 'text/html; charset=UTF-8',
      ['Content-Length'] = #content,
      ['Cache-Control'] = 'public, max-age=' .. options.cache_age,
      ['Expires'] = date('%c', time() + options.cache_age),
      ['Etag'] = etag
    })
  end

return {
  GET = handler
}
