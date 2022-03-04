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
}
build = {
  type = "builtin",
  modules = {
    ["resty.dynacode.controller"] = "src/resty/controller.lua",
    ["resty.dynacode.cache"] = "src/resty/cache.lua",
    ["resty.dynacode.compiler"] = "src/resty/compiler.lua",
    ["resty.dynacode.fetch"] = "src/resty/fetch.lua",
    ["resty.dynacode.opts"] = "src/resty/opts.lua",
    ["resty.dynacode.poller"] = "src/resty/poller.lua",
    ["resty.dynacode.runner"] = "src/resty/runner.lua",
    ["resty.dynacode.validator"] = "src/resty/validator.lua",
  }
}

