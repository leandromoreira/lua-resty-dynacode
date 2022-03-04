local poller = require("resty.dynacode.poller")
local fetcher = require("resty.dynacode.fetch")
local compiler = require("resty.dynacode.compiler")
local opts = require("resty.dynacode.opts")
local validator = require("resty.dynacode.validator")
local cache = require("resty.dynacode.cache")
local json = require "cjson"

local controller = {}

controller.workers_max_jitter = 0
controller.plugin_api_pool_at_init = false
controller.plugin_api_uri = nil
controller.plugin_api_pooling_interval = 30 -- seconds
controller.plugin_api_timeout = 5 -- seconds
controller.regex_options = "o" -- compile and cache https://github.com/openresty/lua-nginx-module#ngxrematch

controller.ready = false
controller.shm = nil

function controller.logger(msg)
  ngx.log(ngx.ERR, msg)
end

controller.validation_rules = {
  validator.present_string("shm"),
  validator.present_string("plugin_api_uri"),
}

function controller.setup(opt)
  local ok, err = validator.valid(controller.validation_rules, opt)
  if not ok then
    controller.logger(err)
    return false, err
  end

  opts.merge(controller, opt)

  -- caching setup
  ok, err = cache.setup({
    logger = controller.logger,
    now = ngx.time,
    ttl = controller.plugin_api_pooling_interval * 0.9,
    ngx_shared = ngx.shared[controller.shm],
  })
  if not ok then
    controller.logger(string.format("it was not possible to setup the cache due to %s", err))
    return false
  end

  -- api fetch setup
  ok, err = fetcher.setup({
    plugin_api_uri = controller.plugin_api_uri,
    start_right_away = controller.plugin_api_pool_at_init,
    plugin_api_timeout = controller.plugin_api_timeout,
  })
  if not ok then
    controller.logger(string.format("it was not possible to setup the fetch api due to %s", err))
    return false
  end

  -- poller setup
  ok, err = poller.setup({
    interval = controller.plugin_api_pooling_interval,
    workers_max_jitter = controller.workers_max_jitter,
    callback = controller.recurrent_function,
    logger = controller.logger,
  })
  if not ok then
    controller.logger(string.format("it was not possible to setup the poller due to %s", err))
    return false
  end

  controller.ready = true
  return true
end


function controller.recurrent_function()
  local response, err

  if cache.should_refresh() then
    response, err = fetcher.request_api()
    if not response then
      controller.logger(string.format("it was not possible to request due to %s", err))
      return
    end
    cache.set(response)
  else
    response = cache.get()
  end

  if not response or response == "" then
    controller.logger("the cache was empty")
    return
  end

  local table_response
  table_response, err = json.decode(response)
  if err ~= nil then
    controller.logger(string.format("there was an error while decoding the api response err=%s", err))
    return
  end

  local errors = compiler.compile(table_response)
  for _, e in ipairs(errors) do
    controller.logger(string.format("[warn] %s", e))
  end

  -- saving/updating the copy locally per worker
  controller.plugins = table_response
end

-- TODO: split code
function controller.run()
  local ok, err = pcall(controller._run)
  if not ok then
    controller.logger(string.format("there was an general error during the run err = %s", err))
  end
end

-- TODO: internalize/localize functions
function controller._run()
  if not controller.ready then
    controller.logger("[NOT_READY] no functions are running, you must properly setup dynacode.setup(opts)")
    return
  end

  local phase = ngx.get_phase()
  if phase == "init_worker" then
    controller.logger(string.format("running the poller for worker pid=%d", ngx.worker.pid()))
    poller.run()
    return
  end

  controller._perform()
end

function controller._perform()
  if controller.plugins == nil then
    controller.logger("the plugins are not loaded yet")
    return
  end

  -- applying general config
  if controller.plugins.general.status ~= "enabled" then
    controller.logger("the plugins are disabled")
    return
  end

  local host = ngx.var.host
  local current_phase = ngx.get_phase()

  -- skipping domains
  if controller.plugins.general.skip_domains then
    for _, domain in  ipairs(controller.plugins.general.skip_domains) do
      if ngx.re.find(host, domain, controller.regex_options) then
        controller.logger(string.format("the domain=%s was skipped to host=", domain, host))
        return
      end
    end
  end

  -- TODO: check order?
  -- filter tasks
  local tasks_to_perform = {}

  for _, domain in ipairs(controller.plugins.domains) do
    -- check if it's for the current server plus applicable to all domains
    if domain.name == "*" or ngx.re.find(host, domain.name, controller.regex_options) then
      for _, plugin in ipairs(domain.plugins) do
        -- only add plugins for the current phase or valid
        if plugin.phase == current_phase and not plugin.skip then
          table.insert(tasks_to_perform, plugin)
        end
      end
    end

  end

  local runtime_errors = {}
  -- perform tasks
  for _, plugin in ipairs(tasks_to_perform) do
    local status, ret = pcall(plugin.compiled_code)
    if not status then
      table.insert(runtime_errors, string.format("the execution of %s failed due to %s", plugin.name, ret))
    end
  end

  if #runtime_errors > 0 then
    for _, err in ipairs(runtime_errors) do
      controller.logger(string.format("[warn] some plugins failed while executing err=%s", err))
    end
  end

end

return controller
