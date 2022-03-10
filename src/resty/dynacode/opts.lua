--- An http client.
local opts = {}

--- Merging function.
-- @param default_values table - the table to be used as default values
-- @param override_values table - the table to merge and override default values
function opts.merge(default_values, override_values)
    for k,v in pairs(override_values) do default_values[k] = v end
end

return opts
