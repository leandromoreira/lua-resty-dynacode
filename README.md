# Lua Resty Dynacode

A library to provide dynamic (via json/API) load of lua code into your nginx/openresty.

# How

* in background
  * start a poller
  * fetch a json api text response and save it to a shared memory
  * compile (`loadstring`) the lua code and share it through *each worker*
* at runtime
  * select the proper domain
  * select the applicable plugins
  * run them

# Observability

One [can use the events](usage/src/controller.lua#L73) to expose metrics about the poller, compiler, plugins, and etc.

## Motivation

Do what we already do with Lua but without SIGHUP or deployment, it was [inspired by a prev hackathon](https://github.com/leandromoreira/edge-computing-resty#demo). Things you might want to do:

* Debug (log/metrify specific IP/token/user agent/cookie)
* Quick maneuver
  * Block IP
  * Deny requests per path/user agent/etc
  * Drain a single server (302) / health check
  * Turn on/off modules/variables
  * ...
* Chaos testing
* Change any variables
* Change response body
* Add response header (CORs, SCP, HSTS, X-Frame-Options,
 ...)
* Really anything you can do with lua/openresty

## Warning

Although this library was made to support most type of failures through `pcall`, fallbacks, reasonable defaults. You can't forget a developer is still writting code.

The following code will keep all your nginx workers busy forever, effectively making it unreachable.

```lua
while true do print('The bullets, Just stop your crying') end
```

While one could try to solve that with [quotas. Luajit doens't allow us to do that](https://github.com/Kong/kong-lua-sandbox).

What happens when plugin API is offline? If the plugins are already in memory that's fine. But when nginx was restarted/reloaded, it's going to lose all the cached data.

## Poll the API for new plugins or updates

![Poll the API for new plugins or updates](/img/background_task.png "Poll the API for new plugins or updates")

## Run the compiled/cached plugins at request time

![Run the compiled/cached plugins at request time](/img/runtime_task.png "Run the compiled/cached plugins at request time")

# Road map

* publish a rock
* off-line mode (saving a local api response for -HUP/restart without link to API)
* use / provide function direct access / local function instead of tables (`ngx_now`, `tbl.logger`)
* discuss the json format (making phases accessible without iterating through all plugins)
* offer events callbacks (like: `on_compile_fail`, `on_success`, `...`)
  * maybe a vts plugin for metrics
* tests
* documentation / drawing / use cases (see: `ldoc_example.lua`)
* build, lint, tests
