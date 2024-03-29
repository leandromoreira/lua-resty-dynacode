# Lua Resty Dynacode

An openresty library provisioning dynamic (via JSON/API) load of lua code into nginx/openresty.

# Quick Start

https://user-images.githubusercontent.com/55913/210108208-6556981d-a59f-43cb-b080-5a2185ea62f2.mp4

You can find the complete example in the [`usage`](/usage) folder. The following steps will guide you through the basic usage:

Install the library: `luarocks install resty-dynacode`

Create a lua module to import and configure the library.

```lua
local dyna_controller = require "resty.dynacode.controller"
local controller = {} -- your module

dyna_controller.setup({
  plugin_api_uri = "http://api:9090/response.json", -- the API providing the expected response
  plugin_api_polling_interval = 15,
  plugin_api_poll_at_init = true,
  workers_max_jitter = 5,
  shm = "cache_dict",
})

function controller.run()
  dyna_controller.run()
end

return controller
```

And finally hooking up the phases at the nginx conf.

```nginx
http {
  # you must provide a shared memory space for caching
  lua_shared_dict cache_dict 1m;
  # spawning the pollers
  init_worker_by_lua_block   { require("controller").run() }
  # hooking up all the phases (on http context)
  rewrite_by_lua_block       { require("controller").run() }
  access_by_lua_block        { require("controller").run() }
  header_filter_by_lua_block { require("controller").run() }
  body_filter_by_lua_block   { require("controller").run() }
  log_by_lua_block           { require("controller").run() }

  # the servers we want to add lua code
  server {
    listen 6060;
    server_name  dynamic.local.com;

    location / {
      content_by_lua_block { require("controller").run() }
    }
  }
}
```

# Motivation

Do what we already do with Lua, but without SIGHUP or deployment. It was [inspired by a previous hackathon](https://github.com/leandromoreira/edge-computing-resty#demo). Things this library enables you to do:

* Debug (log/metrify specific IP/token/user agent/cookie)
* Quick maneuvers:
  * Block IP
  * Deny requests per path/user agent/etc
  * Drain a single server (302) / health check
  * Turn on/off modules/variables
  * ...
* Chaos testing
* Change any variables
* Modify response body
* Add response header (CORs, SCP, HSTS, X-Frame-Options,
 ...)
* Really anything you can do with lua/openresty


# How it works

* in the **background**:
  * start a [poller](/src/resty/dynacode/poller.lua#L40)
  * fetch the [JSON API response](/usage/response.json) and save it to a [**shared memory**](/src/resty/dynacode/cache.lua#L67)
  * compile (`loadstring`) the lua code and share it through [**each worker**](/src/resty/dynacode/controller.lua#L157)
* at the **runtime (request cycle)**:
  * select the proper domain (applying [regex against current host](/src/resty/dynacode/runner.lua#L88))
  * select the applicable plugins (based on phase/applicability)
  * [run them](/src/resty/dynacode/runner.lua#L102)

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

One [can use events](usage/src/controller.lua#L73) to expose metrics about the: `poller`, `fetcher`, `caching`, `compiler`, `runner`, and etc.

# API format to provide functions

You can create a CMS where you'll input your code, AKA **plugins**. A plugin belongs to a **server/domain** (`*`, regex, etc), it has an **nginx phase** (access, rewrite, log, etc), and the **lua code** it represents. Your CMS then must expose these plugins in a known API/structure.

```json
{
   "general": {
      "status": "enabled",
      "skip_domains": [
         "[\\\\w\\\\d\\\\.\\\\-]*server.local.com"
      ]
   },
   "domains": [
      {
         "name": "dynamic.local.com",
         "plugins": [
            {
               "name": "dynamic content",
               "code": "ngx.say(\"olá mundo!\")\r\nngx.say(\"hello world!\")",
               "phase": "content"
            },
            {
               "name": "adding cors headers",
               "code": "ngx.header[\"Access-Control-Allow-Origin\"] = \"http://dynamic.local.com\"",
               "phase": "header_filter"
            },
            {
               "name": "authentication required",
               "code": "local token = ngx.var.arg_token or ngx.var.cookie_superstition\r\n\r\nif token ~= 'token' then\r\n  return ngx.exit(ngx.HTTP_FORBIDDEN)\r\nelse\r\n  ngx.header['Set-Cookie'] = {'superstition=token'}\r\nend",
               "phase": "access"
            }
         ]
      }
   ]
}
```

Once a JSON API is running, the openresty/nginx will `fetch` regularly the plugins (**in background**), `compile` them, and save them to cache. When a regular user issues a request then the `runner` will see if the current context (server name, phase, etc.) matches with the **plugin spec/requirements**, and run it.


# Warning

Although this library was made to support most of the failures types through `pcall`, `fallbacks`, and `sensible defaults` you can't forget that a developer is still writing the code.

The following code will keep all nginx workers busy forever, effectively making it unreachable.

```lua
while true do print('The bullets, Just stop your crying') end
```

While one could try to solve that with [quotas, but Luajit doesn't allow us to use that](https://github.com/Kong/kong-lua-sandbox#optionsquota).

What happens when plugin API is offline? If the plugins are already in memory, that's fine. But when nginx was restarted/reloaded, it's going to `"lose"` all the cached data.


# Road map

* evaluate if having plugins separated from domains might be helpful (re-use among domains)
```json
{
   "general": {
   },
   "domains": [
      {
         "name": "dynamic.local.com",
         "plugins": [1, 2]
      }
   ]
   "plugins": [
            {
               "id": 1,
               "name": "dynamic content",
               "code": "ngx.say(\"olá mundo!\")\r\nngx.say(\"hello world!\")",
               "phase": "content"
            },
            {
               "id": 2,
               "name": "adding cors headers",
               "code": "ngx.header[\"Access-Control-Allow-Origin\"] = \"http://dynamic.local.com\"",
               "phase": "header_filter"
            }
    ]

}
```
> *another way to have a plugin per multiple domains* is to rely on `*` or regexes `.*\.common.com`
* CMS probably would benefit from having plugins code at a git repo (linked through its git path, therefore tested and developed like any other lua code already) and only render them at the response time
* measure the impact of lots of lua code being loaded (even though it's compressed), if there's any need to load the plugins per chunk/domain/whatever
* make CMS run a lua compile phase to avoid uncompiled code being deployed
* enable some way for user to setup the request for polling (providing authentication, and etc)
* avoid re-compilation when no plugins were altered (should we emit `BG_UPDATED_PLUGINS` or a new event)
* review the events adding arguments when necessary/possible (for instance `BG_DIDNT_UPDATE_PLUGINS`)
* ~add a CMS for the complete example~
* ~add a quick start for the complete example~
* evaluate the lua-resty-mlcache rock to replace the current cache system
* ~~publish a rock~~
* evaluate if an off-line mode makes sense (saving a local api response for -HUP/restart without link to API)
* ~~use / provide function direct access / local function instead of tables (`ngx_now`, `tbl.logger`)~~
* ~~discuss the json format (making phases accessible without iterating through all plugins)~~
* ~~offer events callbacks (like: `on_compile_fail`, `on_success`, `...`)~~
  * maybe a vts plugin for metrics
* ~~tests~~
* ~~documentation~~ / ~~drawing~~ / ~~use cases~~
* build, ~~lint~~
