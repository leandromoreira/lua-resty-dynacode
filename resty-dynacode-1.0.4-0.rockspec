package = "resty-dynacode"
version = "1.0.4-0"
source = {
  url = "git://github.com/leandromoreira/lua-resty-dynacode",
  tag = "1.0.4"
}
description = {
  summary = "A resty Lua library to enable dynamic code deployment on nginx / openresty",
  homepage = "https://github.com/leandromoreira/lua-resty-dynacode",
  license = "BSD 3-Clause"
}
dependencies = {
  "lua-resty-http >= 0.16.1-0",
}
build = {
  type = "builtin",
  modules = {
    ["resty.dynacode.controller"] = "src/resty/dynacode/controller.lua",
    ["resty.dynacode.cache"] = "src/resty/dynacode/cache.lua",
    ["resty.dynacode.compiler"] = "src/resty/dynacode/compiler.lua",
    ["resty.dynacode.fetch"] = "src/resty/dynacode/fetch.lua",
    ["resty.dynacode.opts"] = "src/resty/dynacode/opts.lua",
    ["resty.dynacode.poller"] = "src/resty/dynacode/poller.lua",
    ["resty.dynacode.runner"] = "src/resty/dynacode/runner.lua",
    ["resty.dynacode.validator"] = "src/resty/dynacode/validator.lua",
    ["resty.dynacode.event_emitter"] = "src/resty/dynacode/event_emitter.lua",
  }
}

