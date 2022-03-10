--- Provide the basic setup for calling a function in a given interval.
-- It uses the [`ngx.time.every`](https://github.com/openresty/lua-nginx-module#ngxtimerevery).
local spawn = {}

local validator = require "resty.dynacode.validator"
local opts = require "resty.dynacode.opts"

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

--- Setup function.
-- @param opt options to configure the poller
-- @param opt.interval number - the interval in between recurring function calls.
-- @param opt.callback function - the function that will be called "in background"
-- @param opt.workers_max_jitter number - the number of seconds to add jitter among all the nginx workers
-- @return bool - status - if it's a success or not
-- @return string - when there's an error this is the error message
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
