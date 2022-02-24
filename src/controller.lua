--local dyna_controller = require "resty.dynacode.controller"
local controller = {}

--dyna_controller.setup({
--  plugin_api_uri = "http://localhost:9090/plugins.json",
--  plugin_api_pooling_interval = 30,
--  plugin_api_timeout = 5,
--  random_seed = function() return ngx.time() + ngx.worker.pid() end,
--  logger = function(msg)
--    ngx.log(ngx.ERR, "resty_dynacode[" .. ngx.worker.id() .. "] "  .. msg)
--  end,
--})

function controller.run()
  ngx.log(ngx.ERR, "phase=" .. ngx.get_phase())
  if ngx.get_phase() == "content" then
    ngx.say("dynamic content by lua")
  end
end

return controller
