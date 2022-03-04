# Lua Resty Dynacode

A library to provide dynamic (via json/API) load of lua code into your nginx/openresty.

# How

* in background
  * start a poller
  * fetch a json api text response and save it to a shared memory
  * compile (`loadstring`) the lua code and share it through each worker
* at runtime
  * select the proper domain
  * select the proper plugins
  * run them

## Poll the API for new plugins or updates

![Poll the API for new plugins or updates](/img/background_task.png "Poll the API for new plugins or updates")

## Run the compiled/cached plugins at request time

![Run the compiled/cached plugins at request time](/img/runtime_task.png "Run the compiled/cached plugins at request time")

# Road map

* publish a rock
* off-line mode (saving a local api response for -HUP/restart without link to API)
* discuss the json format (making phases accessible without iterating through all plugins)
* offer events callbacks (like: `on_compile_fail`, `on_success`, `...`)
  * maybe a vts plugin for metrics
* tests
* documentation / drawing / use cases (see: `ldoc_example.lua`)
* build, lint, tests
