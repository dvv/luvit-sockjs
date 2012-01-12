local OS = require('os')
local date, time = OS.date, OS.time

return function(self, options)
  self:handle_xhr_cors()
  self:handle_balancer_cookie()
  self:send(204, nil, {
    ['Allow-Control-Allow-Methods'] = 'OPTIONS, POST',
    ['Cache-Control'] = 'public, max-age=' .. options.cache_age,
    ['Expires'] = date('%c', time() + options.cache_age),
    ['Access-Control-Max-Age'] = tostring(options.cache_age)
  })
end
