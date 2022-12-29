# Lua Resty Dynacode Usage

```bash
make run # it'll run all the services

# just checking if the services are up

http localhost:5050 Host:metrics.server.local.com # it'll hit the metrics service
http localhost:6060 Host:dynamic.local.com # dynamic should be empty, we'll add the content through a lua plugin
http localhost:7070 Host:clock.local.com # should be working just fine, we'll add cors Headers to this service

# if you check your plugins API http://localhost:3000/plugins/index.json it should be empty

# let's add some domains and plugins
# access http://localhost:3000/admin/ and register the domains dynamic.local.com and clock.local.com.
# now onto adding plugins http://localhost:3000/admin/plugins

# one of them will be tied to dynamic.local.com, in the content phase and it will print hello world
# the other will be linked to clock.local.com and it's going to add a CORS headers

# after the registration the plugins should be loaded by the POLL time and you can check the services again

http localhost:5050 Host:metrics.server.local.com # it should contain more metrics
http localhost:6060 Host:dynamic.local.com # it should respond hello world
http localhost:7070 Host:clock.local.com # it should respond the CORS headers
```
