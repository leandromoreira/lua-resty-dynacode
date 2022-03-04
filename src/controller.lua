local dyna_controller = require "resty.dynacode.controller"
local controller = {}


local ok, err = dyna_controller.setup({
  plugin_api_uri = "http://localhost:9090/response.json",
  plugin_api_polling_interval = 15,
  workers_max_jitter = 5,
  shm = "cache_dict",
  plugin_api_poll_at_init = true,
})

if not ok then
  ngx.log(ngx.ERR, string.format("error during the setup err=%s",err))
end

function controller.run()
  dyna_controller.run()
end

return controller
