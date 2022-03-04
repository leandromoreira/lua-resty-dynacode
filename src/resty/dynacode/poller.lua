local validator = require "resty.dynacode.validator"
local opts = require "resty.dynacode.opts"

local spawn = {}

spawn.interval = nil
spawn.workers_max_jitter = nil
spawn.callback = nil
spawn.start_right_away = false
spawn.ready = false
spawn.validation_rules = {
  validator.present_number("interval"),
  validator.present_number("workers_max_jitter"),
  validator.present_function("callback"),
}

function spawn.logger(msg) print(msg) end

function spawn.setup(opt)
  local ok, err = validator.valid(spawn.validation_rules, opt)
  if not ok then
    return false, err
  end

  opts.merge(spawn, opt)
  spawn.ready = true

  return true, nil
end

function spawn.run()
  if not spawn.ready then
    spawn.logger("the poller was not properly setup")
    return
  end

  -- starting luajit entropy per worker
  math.randomseed(ngx.time() + ngx.worker.pid())

  local jitter_seconds = math.random(1, spawn.workers_max_jitter)
  local worker_interval_seconds = spawn.interval + jitter_seconds

  -- scheduling recurring task
  ngx.timer.every(worker_interval_seconds, spawn.callback)

  -- polling right away (in the next nginx "cicle") is enabled
  -- then avoid all the workers requesting at the same time, we added a possible jitter of 5s TODO: configurable
  if spawn.start_right_away then ngx.timer.at(0 + math.random(0, 5), spawn.callback) end
end

return spawn
