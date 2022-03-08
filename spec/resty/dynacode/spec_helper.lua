local spec_helper = {}

function spec_helper.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[spec_helper.deepcopy(orig_key)] = spec_helper.deepcopy(orig_value)
        end
        setmetatable(copy, spec_helper.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

return spec_helper
