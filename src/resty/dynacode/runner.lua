--- The plugin runner, it hooks to nginx phases and do filtering (based on regex) and do a procted call to the plugins.
local runner = {}

local validator = require "resty.dynacode.validator"
local opts = require "resty.dynacode.opts"

runner.logger = function(msg) print(msg) end
runner.regex_options = "o"
runner.events = nil

runner.validation_rules = {
  validator.present_table("events"),
}

function runner.setup(opt)
  local ok, err = validator.valid(runner.validation_rules, opt)
  if not ok then
    return false, err
  end

  opts.merge(runner, opt)
  return true, nil
end

-- It facilitates the run phase, avoids looping through all the plugins restricting only for the current phase.
function runner.phasify_plugins(plugins)
  local ok, err = runner.plugins_ready(plugins)
  if not ok then
    runner.logger(err)
    return plugins
  end


  if plugins.domains == nil then
    runner.logger("plugins api response is missing the domains section")
    return plugins
  end

  for _, domain in ipairs(plugins.domains) do
    for _, plugin in ipairs(domain.plugins) do
      if domain[plugin.phase] == nil then
        domain[plugin.phase] = {}
      end

      table.insert(domain[plugin.phase], plugin)
    end
  end

  return plugins
end

--- Runner main function.
-- @param plugins table - the plugins scheme to run
-- @param host string - the current host
-- @param curren_phase string - the current phase
-- @return bool - status - if it's a success or not
-- @return string - when there's an error this is the error message
function runner.run(plugins, host, current_phase)
  if plugins == nil then
    runner.logger("the plugins are not loaded yet")
    runner.events.emit(runner.events.RT_PLUGINS_NOT_LOADED)
    return
  end

  -- applying general config
  if plugins.general.status ~= "enabled" then
    runner.logger("the plugins are disabled")
    runner.events.emit(runner.events.RT_PLUGINS_DISABLED)
    return
  end

  -- skipping domains
  if plugins.general.skip_domains then
    for _, domain in  ipairs(plugins.general.skip_domains) do
      if ngx.re.find(host, domain, runner.regex_options) then
        runner.logger(string.format("the domain=%s was skipped to host=%s", domain, host))
        return
      end
    end
  end

  -- TODO: check order?
  -- filter tasks
  local tasks_to_perform = {}

  for _, domain in ipairs(plugins.domains) do
    -- check if it's for the current server plus applicable to all domains (*)
    if domain.name == "*" or ngx.re.find(host, domain.name, runner.regex_options) then
      if domain[current_phase] ~= nil then
        for _, plugin in ipairs(domain[current_phase]) do
          if not plugin.skip then table.insert(tasks_to_perform, plugin) end
        end
      end
    end

  end

  local runtime_errors = {}
  -- perform tasks
  for _, plugin in ipairs(tasks_to_perform) do
    runner.events.emit(runner.events.RT_PLUGINS_STARTING, plugin)
    local status, ret = pcall(plugin.compiled_code)

    if not status then
      table.insert(runtime_errors, string.format("the execution of %s failed due to %s", plugin.name, ret))
      runner.events.emit(runner.events.RT_PLUGINS_ERROR, plugin, ret)
    else
      runner.events.emit(runner.events.RT_PLUGINS_DONE, plugin)
    end
  end

  if #runtime_errors > 0 then
    for _, err in ipairs(runtime_errors) do
      runner.logger(string.format("[warn] some plugins failed while executing err=%s", err))
    end
  end

end

function runner.plugins_ready(plugins)
    if plugins == nil then
    return false, "the plugins are not loaded yet"
  end

  if plugins.general == nil then
    return false, "the plugins doesnt have a general section"
  end

  if plugins.general.status ~= "enabled" then
    return false, "the plugins are disabled"
  end

  return true, nil
end

return runner
