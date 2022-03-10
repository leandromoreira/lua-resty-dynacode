--- Provide the compiling capabilities.
-- It uses the Lua's [`loadstring`](https://www.lua.org/pil/8.html).
local compiler = {}

local validator = require "resty.dynacode.validator"
local opts = require "resty.dynacode.opts"

compiler.events = nil

compiler.validation_rules = {
  validator.present_table("events"),
}

function compiler.setup(opt)
  local ok, err = validator.valid(compiler.validation_rules, opt)
  if not ok then
    return false, err
  end

  opts.merge(compiler, opt)

  return true, nil
end

local function compiler_loadstring(str_code)
  local api_fun, err = loadstring("return function() " .. str_code .. " end")
  if api_fun then
    return api_fun(), nil
  else
    return nil, err
  end
end

--- Compiler function.
-- @param api_response table the api response in lua table format
-- @return [error] - the compilation error list
function compiler.compile(api_response)
  local errors = {}

  for _, domain in ipairs(api_response.domains) do
    for _, plugin in ipairs(domain.plugins) do
      local compiled_fun, err = compiler_loadstring(plugin.code)

      if not compiled_fun then
        plugin.skip = true -- avoid runnning it
        err = string.format("the plugin %s raised an error %s during compilation", plugin.name, err)
        table.insert(errors, err)
        compiler.events.emit(compiler.events.BG_COMPILE_ERROR, plugin, err)
      else
        plugin.compiled_code = compiled_fun -- adding the compiled function
        compiler.events.emit(compiler.events.BG_COMPILE_SUCCESS, plugin)
      end

    end
  end

  return errors
end

return compiler
