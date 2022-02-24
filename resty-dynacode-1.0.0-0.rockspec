package = "resty-dynacode"
version = "1.0.0-0"
source = {
  url = "github.com/leandromoreira/lua-resty-dynacode",
  tag = "1.0.0"
}
description = {
  summary = "A resty Lua library to enable dynamic code deployment on nginx / openresty",
  homepage = "https://github.com/leandromoreira/lua-resty-dynacode",
  license = "BSD 3-Clause"
}
dependencies = {
  "lua-resty-http >= 5.1, < 5.2",
  "lua-resty-mlcache == 2.5.0-1",
}
build = {
  type = "builtin",
  modules = {
    ["resty-redis-rate"] = "src/resty-redis-rate.lua"
  }
}

