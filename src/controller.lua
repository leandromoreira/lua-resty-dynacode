local dyna_controller = require "resty.dynacode.controller"
local controller = {}


local ok, err = dyna_controller.setup({
  plugin_api_uri = "http://localhost:9090/response.json",
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

if not ok then
  ngx.log(ngx.ERR, string.format("error during the setup err=%s",err))
end

function controller.run()
  dyna_controller.run()
end

return controller
