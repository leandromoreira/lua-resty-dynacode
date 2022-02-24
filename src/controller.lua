local dyna_controller = require "resty.dynacode.controller"
local controller = {}

dyna_controller.setup({
  plugin_api_uri = "http://localhost:9090/response.json",
  plugin_api_pooling_interval = 15,
  shm = "cache_dict",
})

function controller.run()
  ngx.log(ngx.ERR, "running the phase=" .. ngx.get_phase())

  if ngx.get_phase() == "content" then
    ngx.say("dynamic content by lua")
  end

  dyna_controller.run()
end

return controller
