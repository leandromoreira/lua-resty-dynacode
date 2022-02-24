local poller = require("resty.dynacode.poller")
local fetcher = require("resty.dynacode.fetch")
local opts = require("resty.dynacode.opts")
local mlcache = require("resty.mlcache")

local controller = {}

controller.workers_max_jitter = 0
controller.plugin_poll_interval = 15
controller.plugin_poll_fetch_function = fetcher.fetch_code
controller.fetch_at_start = false

controller.ready = false
controller.shm = nil
controller.cache_name = "my_cache"
controller.cache_lru_size = 10
controller.cache_neg_ttl = 0

controller.plugin_api_uri = nil
controller.plugin_api_pooling_interval = 30
controller.plugin_api_timeout = 5
controller.plugin_api_cache_key = "dynacode_response"

function controller.logger(msg)
  ngx.log(ngx.ERR, msg)
end

function controller.setup(user_opts)
  local mandatory_options = {"shm", "plugin_api_uri"}

  for _, v in pairs(mandatory_options) do
    if not user_opts[v] then
      controller.logger("you must inform the " .. v)
      return
    end
  end

  opts.merge(controller, user_opts)

  local cache, err = mlcache.new(controller.cache_name, controller.shm, {
    lru_size = controller.cache_lru_size,
    ttl      = controller.plugin_poll_interval / 2,
    neg_ttl  = controller.cache_neg_ttl,
  })
  if err then
    controller.logger("there was an error during the cache setup err=" .. err)
    return
  end

  fetcher.cache_key = controller.plugin_api_cache_key
  fetcher.plugin_api_uri = controller.plugin_api_uri
  fetcher.plugin_api_pooling_interval = controller.plugin_api_pooling_interval or 30
  fetcher.plugin_api_timeout = controller.plugin_api_timeout or 5
  fetcher.cache = cache
  controller.cache = cache

  controller.ready = true
end

function controller.run()
  if not controller.ready then
    ngx.log(ngx.ERR, "no dynamic functions are running, you must properly setup dynacode.setup(opts)")
    return
  end

  local phase = ngx.get_phase()
  if controller.ready and phase == "init_worker" then
    controller.spawn_poller()
    return
  end

  if controller.cache:get(controller.plugin_api_cache_key) then
    local response = controller.cache:get(controller.plugin_api_cache_key)
    controller.logger("general.status=" .. response.general.status)
  end

end

function controller.spawn_poller()
  poller.poll(controller.plugin_poll_fetch_function, {
    workers_max_jitter = controller.workers_max_jitter,
    interval = controller.plugin_poll_interval,
    fetch_at_start = controller.plugin_poll_force_at_start,
  })
end

return controller
