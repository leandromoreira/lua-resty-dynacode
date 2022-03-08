# Lua Resty Dynacode

A library to provide dynamic (via JSON/API) load of lua code into your nginx/openresty.

# Example

You can find a complete example at [`usage`](/usage) folder.

# How

* in the background:
  * start a [poller](/src/resty/dynacode/poller.lua#L44)
  * fetch the [JSON API response](/usage/response.json) and save it to a [**shared memory**](/src/resty/dynacode/cache.lua#L43)
  * compile (`loadstring`) the lua code and share it through [**each worker**](/src/resty/dynacode/controller.lua#L157)
* at the runtime (request cycle):
  * select the proper domain (applying [regex against current host](/src/resty/dynacode/runner.lua#L57))
  * select the applicable plugins (based on phase/applicability)
  * [run them](/src/resty/dynacode/runner.lua#L72)

## Background 

```mermaid
graph LR
    subgraph Nginx/Openresty Background
        DynaCode -->|run each X seconds| Poller
        Poller -->|already in cache| Cache[(Cache SHM)]
        Poller -->|GET /plugins.json| Fetcher
        Fetcher --> Cache
        Cache --> Compiler[[Compiler]]
        Compiler --> |share bytecode| LocalLuaVM([LocalLuaVM])
    end
```

## Request

```mermaid
graph LR
    subgraph Nginx/Openresty Request
        Runner -->|library is| Enabled
        Runner -->|host is not| Skippable
        Runner -->|host matches| Regex
        Runner -->|matches current| Phase
        Runner -->|execute the function| LocalLuaVM([LocalLuaVM])
    end
```

# Observability

One [can use events](usage/src/controller.lua#L73) to expose metrics about the poller, fetche, caching, compiler, plugins, etc.

## Motivation

Do what we already do with Lua, but without SIGHUP or deployment, it was [inspired by a previous hackathon](https://github.com/leandromoreira/edge-computing-resty#demo). Things this library enables you to do:

* Debug (log/metrify specific IP/token/user agent/cookie)
* Quick maneuvers:
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

Although this library was made to support the most failures types through `pcall`, fallbacks, sensible defaults. You can't forget that a developer is still writing the code.

The following code will keep all nginx workers busy forever, effectively making it unreachable.

```lua
while true do print('The bullets, Just stop your crying') end
```

While one could try to solve that with [quotas, but Luajit doesn't allow us to do that](https://github.com/Kong/kong-lua-sandbox).

What happens when plugin API is offline? If the plugins are already in memory, that's fine. But when nginx was restarted/reloaded, it's going to lose all the cached data.


# Road map

* ~~publish a rock~~
* off-line mode (saving a local api response for -HUP/restart without link to API)
* use / provide function direct access / local function instead of tables (`ngx_now`, `tbl.logger`)
* discuss the json format (making phases accessible without iterating through all plugins)
* ~~offer events callbacks (like: `on_compile_fail`, `on_success`, `...`)~~
  * maybe a vts plugin for metrics
* tests
* documentation / ~~drawing~~ / ~~use cases~~
* build, ~~lint~~
