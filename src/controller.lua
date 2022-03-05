local dyna_controller = require "resty.dynacode.controller"
local controller = {}


local ok, err = dyna_controller.setup({
  plugin_api_uri = "http://api:9090/response.json",
  plugin_api_polling_interval = 15,
  plugin_api_poll_at_init = true,
  workers_max_jitter = 5,
  shm = "cache_dict",
})

dyna_controller.events.on(dyna_controller.events.BG_CACHE_HIT, function()
  ngx.log(ngx.ERR, "cache hit")
end)

dyna_controller.events.on(dyna_controller.events.BG_CACHE_MISS, function()
  ngx.log(ngx.ERR, "cache miss")
end)

dyna_controller.events.on(dyna_controller.events.BG_FETCH_API_SUCCESS, function()
  ngx.log(ngx.ERR, "api success")
end)

dyna_controller.events.on(dyna_controller.events.BG_COMPILE_SUCCESS, function(plugin)
  ngx.log(ngx.ERR, string.format("compile success %s", plugin.name))
end)

dyna_controller.events.on(dyna_controller.events.BG_COMPILE_ERROR, function(plugin, err)
  ngx.log(ngx.ERR, string.format("compile error %s err=%s", plugin.name, err))
end)

dyna_controller.events.on(dyna_controller.events.RT_PLUGINS_STARTING, function(plugin)
  ngx.log(ngx.ERR, string.format("about to run %s", plugin.name))
end)

dyna_controller.events.on(dyna_controller.events.RT_PLUGINS_DONE, function(plugin)
  ngx.log(ngx.ERR, string.format("done running %s", plugin.name))
end)

dyna_controller.events.on(dyna_controller.events.RT_PLUGINS_ERROR, function(plugin, err)
  ngx.log(ngx.ERR, string.format("error while running %s err=%s", plugin.name, err))
end)

if not ok then
  ngx.log(ngx.ERR, string.format("error during the setup err=%s",err))
end

function controller.run()
  dyna_controller.run()
end

return controller
