local validator = require "resty.dynacode.validator"
local opts = require "resty.dynacode.opts"

local runner = {}

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

function runner.run(plugins)
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

  local host = ngx.var.host
  local current_phase = ngx.get_phase()

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
    -- check if it's for the current server plus applicable to all domains
    if domain.name == "*" or ngx.re.find(host, domain.name, runner.regex_options) then
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

return runner
