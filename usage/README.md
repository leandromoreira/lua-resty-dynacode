# Lua Resty Dynacode Usage

## Motivation

Do what we already do with Lua but without SIGHUP or deployment. Things you might want to do:

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

The following code will keep all your nginx workers busy forever, effectively making it unreachable.

```lua
while true do print('The bullets, Just stop your crying') end
```

What happens when plugin API is offline? If the plugins are already in memory that's fine. But when nginx was restarted/reloaded, it's going to lose all the cached data.
