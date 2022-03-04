local compiler = {}

function compiler.compile(api_response)
  local errors = {}

  for _, domain in ipairs(api_response.domains) do
    for _, plugin in ipairs(domain.plugins) do
      local compiled_fun, err = compiler.loadstring(plugin.code)

      if not compiled_fun then
        plugin.skip = true -- avoid runnning it
        err = string.format("the plugin %s raised an error %s during compilation", plugin.name, err)
        table.insert(errors, err)
      else
        plugin.compiled_code = compiled_fun -- adding the compiled function
      end

    end
  end

  return errors
end

function compiler.loadstring(str_code)
  -- API wrapper
  local api_fun, err = loadstring("return function() " .. str_code .. " end")
  if api_fun then
    return api_fun(), nil
  else
    return nil, err
  end
end

return compiler
