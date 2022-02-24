local opts = {}

function opts.merge(default_values, override_values)
    for k,v in pairs(override_values) do default_values[k] = v end
end

return opts
