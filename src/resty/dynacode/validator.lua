local validator = {}

function validator.present_string(name)
  return {name = name, kind = "string"}
end

function validator.present_number(name)
  return {name = name, kind = "number"}
end

function validator.present_function(name)
  return {name = name, kind = "function"}
end

function validator.present_table(name)
  return {name = name, kind = "table"}
end

function validator.valid(rules, tbl)
  for _, v in pairs(rules) do
    if not tbl[v.name] or type(tbl[v.name]) ~= v.kind then
      return false, string.format("the property %s must be a %s", v.name, v.kind)
    end
  end

  return true, nil
end

return validator
