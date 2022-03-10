--- Provide a caching mechanism for the plugins API response.
-- It uses the [`nginx shared memory`](https://github.com/openresty/lua-nginx-module#ngxshareddict) as the backend storage.
-- It is shared among all the workers.
local cache = {}

local validator = require "resty.dynacode.validator"
local opts = require "resty.dynacode.opts"

cache.key_name = "dynacode_key"
cache.ttl_name = "dynacode_updated_at"
cache.now = nil
cache.ttl = nil
function cache.logger(msg) print(msg) end

cache.validation_rules = {
  validator.present_function("now"),
  validator.present_number("ttl"),
  validator.present_table("ngx_shared"),
}

--- Setup function.
-- @param opt options to configure the caching
-- @param opt.now function - a function that returns epoch now.
-- @param opt.ttl number - after the ttl the cache should be refreshed
-- @return bool - status - if it's a success or not
-- @return string - when there's an error this is the error message
function cache.setup(opt)
  local ok, err = validator.valid(cache.validation_rules, opt)
  if not ok then
    return false, err
  end

  opts.merge(cache, opt)

  return true, nil
end

--- Should fresh.
-- it returns whether the client should refill the cache or not.
-- @return bool - status - if it's a success or not
function cache.should_refresh()
  local value, _ = cache.ngx_shared:get(cache.ttl_name)

  if value == nil then return true end
  if cache.now() > value then return true end

  return false
end

--- Cache get.
-- it returns the cache value.
-- @return string - api response
function cache.get()
  local value, _ = cache.ngx_shared:get(cache.key_name)
  return value
end

--- Cache set.
-- it sets the cache value.
-- @param string value
function cache.set(value)
  if value == nil or value == "" or type(value) ~= "string" then
    cache.logger("the value is invalid (either nil or empty or not a string)")
    return
  end

  local ok, err = cache.ngx_shared:set(cache.key_name, value)
  if not ok then
    cache.logger(string.format("failed to set the cache due to err=%s", err))
    return
  end

  local next_time_to_refresh = cache.now() + cache.ttl
  ok, err = cache.ngx_shared:set(cache.ttl_name, next_time_to_refresh)
  if not ok then
    cache.logger(string.format("failed to set updated at due to err=%s", err))
    return
  end
end

return cache
