local spawn = {}
local mandatory_opts = {"workers_max_jitter", "interval"}

function spawn.logger(msg)
  ngx.log(ngx.ERR, msg)
end

function spawn.poll(callback, opts)

  if not callback or type(callback) ~= "function" then
    spawn.logger("you must inform a proper callback function")
    return
  end

  for _, v in pairs(mandatory_opts) do
    if not opts[v] then
      spawn.logger("you must inform " .. v)
      return
    end
  end

  ngx.log(ngx.ERR, "poll")
  -- starting luajit entropy per worker
  math.randomseed(ngx.time() + ngx.worker.pid())

  local jitter_seconds = math.random(1, opts.workers_max_jitter)
  local worker_interval_seconds = opts.interval + jitter_seconds

  -- scheduling recurring a polling
  ngx.timer.every(worker_interval_seconds, callback)

  -- polling right away (in the next nginx "cicle")
  -- to avoid all the workers to go downstream we add a jitter of 60s
  if opts.fetch_at_start then ngx.timer.at(0 + math.random(0, 60), callback) end
end

return spawn
