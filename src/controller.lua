local dyna_controller = require "resty.dynacode.controller"
local controller = {}

local ok, setup_err = dyna_controller.setup({
  plugin_api_uri = "http://api:9090/response.json",
  plugin_api_polling_interval = 15,
  plugin_api_poll_at_init = true,
  workers_max_jitter = 5,
  shm = "cache_dict",
})
if not ok then
  ngx.log(ngx.ERR, string.format("error during the setup err=%s", setup_err))
end

dyna_controller.events.on(dyna_controller.events.BG_CACHE_HIT, function()
  ngx.log(ngx.ERR, "cache hit")
end)

dyna_controller.events.on(dyna_controller.events.BG_CACHE_MISS, function()
  ngx.log(ngx.ERR, "cache miss")
end)

dyna_controller.events.on(dyna_controller.events.BG_FETCH_API_SUCCESS, function()
  ngx.log(ngx.ERR, "api success")
end)

dyna_controller.events.on(dyna_controller.events.BG_FETCH_API_STATUS_CODE_ERROR, function(status_code)
  ngx.log(ngx.ERR, string.format("api <> 200 status=%d", status_code))
end)

dyna_controller.events.on(dyna_controller.events.BG_FETCH_API_GENERIC_ERROR, function(err)
  ngx.log(ngx.ERR, string.format("api err=%s", err))
end)

dyna_controller.events.on(dyna_controller.events.BG_COMPILE_SUCCESS, function(plugin)
  ngx.log(ngx.ERR, string.format("compile success %s", plugin.name))
end)

dyna_controller.events.on(dyna_controller.events.BG_COMPILE_ERROR, function(plugin, err)
  ngx.log(ngx.ERR, string.format("compile error %s err=%s", plugin.name, err))
end)

dyna_controller.events.on(dyna_controller.events.BG_UPDATED_PLUGINS, function()
  ngx.log(ngx.ERR, "updated plugins with success")
end)

dyna_controller.events.on(dyna_controller.events.BG_DIDNT_UPDATE_PLUGINS, function()
  ngx.log(ngx.ERR, "didnt updated plugins with success")
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

dyna_controller.events.on(dyna_controller.events.ON_ERROR, function(section, err)
  ngx.log(ngx.ERR, string.format("error at %s err=%s", section, err))
end)

function controller.run()
  dyna_controller.run()
end

return controller
