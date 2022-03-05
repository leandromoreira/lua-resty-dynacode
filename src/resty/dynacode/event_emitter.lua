local event_emitter = {}

event_emitter.events = {}
-- event list
--  events that happens on background

event_emitter.BG_CACHE_MISS = 'bg_cache_miss' -- happens when a worker must request the API (no args)
event_emitter.BG_CACHE_HIT = 'bg_cache_hit' -- happens when a worker avoid doing requests (no args)

event_emitter.BG_FETCH_API_GENERIC_ERROR = 'bg_fetch_api_generic_error' -- happens when a worker is unable to finish the request (error)
event_emitter.BG_FETCH_API_STATUS_CODE_ERROR = 'bg_fetch_api_status_code_error' -- happens when a worker successfully receive the response non http status code 200 (status code)
event_emitter.BG_FETCH_API_SUCCESS = 'bg_fetch_api_success' -- happens when a worker successfully receive the response (no args)

event_emitter.BG_COMPILE_ERROR = 'bg_compile_error' -- happens when a plugin code provided by users fails to compile (plugin, error)
event_emitter.BG_COMPILE_SUCCESS = 'bg_compile_success' -- happens when a plugin code provided by users compiles successfully (plugin)

event_emitter.BG_UPDATED_PLUGINS = 'bg_updated_plugins' -- happens when the plugins (fully or partially) are updated (no args)
event_emitter.BG_DIDNT_UPDATE_PLUGINS = 'bg_didnt_update_plugins' -- happens when the plugins (fully or partially) aren't updated (no args)

--  events that happens on request time

event_emitter.RT_PLUGINS_NOT_LOADED = 'rt_plugins_not_loaded' -- happens when the plugins are not loaded yet (no args)
event_emitter.RT_PLUGINS_DISABLED = 'rt_plugins_disabled' -- happens when all the plugins are disabled (no args)
event_emitter.RT_PLUGINS_STARTING = 'rt_plugins_starting' -- happens when a plugins is about to run (plugin)
event_emitter.RT_PLUGINS_DONE = 'rt_plugins_done' -- happens when a plugins had ran (plugin)
event_emitter.RT_PLUGINS_ERROR = 'rt_plugins_error' -- happens when there was an error while running a plugin (plugin, err)

--  general events

event_emitter.ON_ERROR = 'on_error' -- happens when there was an error while running the lib (section, err)

function event_emitter.on(event_name, callback)
  if event_emitter.events[event_name] == nil then
    event_emitter.events[event_name] = {}
  end

  table.insert(event_emitter.events[event_name], callback)
end

function event_emitter.emit(event_name, ...)
  if event_emitter.events[event_name] ~= nil then
    for _, callback in ipairs(event_emitter.events[event_name]) do
      if arg then
        callback(unpack(arg))
      else
        callback()
      end
    end
  end
end

return event_emitter
