local JSON = require('json')
local OS = require('os')
local date, time = OS.date, OS.time

local delay = require('timer').set_timeout

local Math = require('math')

return {

  GET = function (self, options)
    self:handle_xhr_cors()
    self:set_code(200)
    self:set_header('Content-Type', 'application/json; charset=UTF-8')
    self:set_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
    self:finish(JSON.stringify({
      websocket = options.websocket,
      cookie_needed = options.cookie_needed,
      origins = options.origins,
      entropy = Math.random(0, 0xFFFFFFFF),
    }))
  end,

  OPTIONS = function (self, options)
    self:handle_xhr_cors()
    self:handle_balancer_cookie()
    self:send(204, nil, {
      ['Allow-Control-Allow-Methods'] = 'OPTIONS, GET',
      ['Cache-Control'] = 'public, max-age=' .. options.cache_age,
      ['Expires'] = date('%c', time() + options.cache_age),
      ['Access-Control-Max-Age'] = tostring(options.cache_age)
    })
  end

}
