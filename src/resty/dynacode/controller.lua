local poller = require("resty.dynacode.poller")
local fetcher = require("resty.dynacode.fetch")
local compiler = require("resty.dynacode.compiler")
local runner = require("resty.dynacode.runner")
local opts = require("resty.dynacode.opts")
local validator = require("resty.dynacode.validator")
local cache = require("resty.dynacode.cache")
local event_emitter = require("resty.dynacode.event_emitter")
local json = require "cjson"

local controller = {}

controller.workers_max_jitter = 0
controller.plugin_api_poll_at_init = false
controller.plugin_api_uri = nil
controller.plugin_api_polling_interval = 30 -- seconds
controller.plugin_api_timeout = 5 -- seconds
controller.regex_options = "o" -- compile and cache https://github.com/openresty/lua-nginx-module#ngxrematch

controller.ready = false
controller.shm = nil

controller.events = event_emitter

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
    controller.events.on(controller.events.ON_ERROR, 'validation', err)
    controller.logger(err)
    return false, err
  end

  opts.merge(controller, opt)

  -- caching setup
  ok, err = cache.setup({
    logger = controller.logger,
    now = ngx.time,
    ttl = controller.plugin_api_polling_interval * 0.9,
    ngx_shared = ngx.shared[controller.shm],
  })
  if not ok then
    controller.logger(string.format("it was not possible to setup the cache due to %s", err))
    controller.events.on(controller.events.ON_ERROR, 'setup', err)
    return false
  end

  -- compiler setup
  ok, err = compiler.setup({
    events = controller.events,
  })
  if not ok then
    controller.logger(string.format("it was not possible to setup the compiler due to %s", err))
    controller.events.on(controller.events.ON_ERROR, 'setup', err)
    return false
  end

  -- runner setup
  ok, err = runner.setup({
    logger = controller.logger,
    regex_options = controller.regex_options,
    events = controller.events,
  })
  if not ok then
    controller.logger(string.format("it was not possible to setup the runner due to %s", err))
    controller.events.on(controller.events.ON_ERROR, 'setup', err)
    return false
  end

  -- api fetch setup
  ok, err = fetcher.setup({
    plugin_api_uri = controller.plugin_api_uri,
    plugin_api_timeout = controller.plugin_api_timeout,
    events = controller.events,
  })
  if not ok then
    controller.logger(string.format("it was not possible to setup the fetch api due to %s", err))
    controller.events.on(controller.events.ON_ERROR, 'setup', err)
    return false
  end

  -- poller setup
  ok, err = poller.setup({
    interval = controller.plugin_api_polling_interval,
    workers_max_jitter = controller.workers_max_jitter,
    callback = controller.recurrent_function,
    start_right_away = controller.plugin_api_poll_at_init,
    logger = controller.logger,
  })
  if not ok then
    controller.logger(string.format("it was not possible to setup the poller due to %s", err))
    controller.events.on(controller.events.ON_ERROR, 'setup', err)
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
    event_emitter.emit(event_emitter.BG_CACHE_MISS)
  else
    response = cache.get()
    event_emitter.emit(event_emitter.BG_CACHE_HIT)
  end

  if not response or response == "" then
    controller.logger("the cache was empty")
    event_emitter.emit(event_emitter.BG_DIDNT_UPDATE_PLUGINS)
    return
  end

  local table_response
  table_response, err = json.decode(response)
  if err ~= nil then
    controller.logger(string.format("there was an error while decoding the api response err=%s", err))
    event_emitter.emit(event_emitter.BG_DIDNT_UPDATE_PLUGINS)
    return
  end

  local errors = compiler.compile(table_response)
  for _, e in ipairs(errors) do
    controller.logger(string.format("[warn] %s", e))
  end

  -- TODO: validate plugins minimal expected structure to not override current with invalid api response
  -- saving/updating the copy locally per worker
  controller.plugins = table_response
  event_emitter.emit(event_emitter.BG_UPDATE_PLUGINS)
end

function controller.run()
  local ok, err = pcall(controller._run)
  if not ok then
    controller.events.on(controller.events.ON_ERROR, 'general_run', err)
    controller.logger(string.format("there was an general error during the run err = %s", err))
  end
end

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

  runner.run(controller.plugins)
end

return controller
