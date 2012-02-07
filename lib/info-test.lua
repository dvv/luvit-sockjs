local JSON = require('json')
local OS = require('os')
local date, time = OS.date, OS.time

local delay = require('timer').setTimeout

local Math = require('math')

return {

  GET = function (self, options)
    self:handle_xhr_cors()
    self:setCode(200)
    self:setHeader('Content-Type', 'application/json; charset=UTF-8')
    self:setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
    self:finish(JSON.stringify({
      websocket = options.websocket,
      cookie_needed = options.cookie_needed,
      origins = options.origins,
      entropy = Math.random(0, 0x7FFFFFFF),
    }))
  end,

  OPTIONS = function (self, options)
    self:handle_xhr_cors()
    self:handle_balancer_cookie()
    self:send(204, nil, {
      ['Cache-Control'] = 'public, max-age=' .. options.cache_age,
      ['Expires'] = date('%c', time() + options.cache_age),
      ['Access-Control-Allow-Methods'] = 'OPTIONS, GET',
      ['Access-Control-Max-Age'] = tostring(options.cache_age)
    })
  end

}
