local http = require "resty.http"
local opts = require("resty.dynacode.opts")
local validator = require "resty.dynacode.validator"

local fetch = {}
local MS = 1000 -- ms to convert seconds

fetch.plugin_api_uri = nil
fetch.plugin_api_timeout = 5
fetch.plugin_api_params = nil

fetch.validation_rules = {
  validator.present_string("plugin_api_uri"),
}

function fetch.setup(opt)
  local ok, err = validator.valid(fetch.validation_rules, opt)
  if not ok then
    return false, err
  end

  opts.merge(fetch, opt)

  return true, nil
end

function fetch.request_api()
  local httpc = http.new()
  httpc:set_timeout(fetch.plugin_api_timeout * MS)
  local res_api, err_api = httpc:request_uri(fetch.plugin_api_uri, fetch.plugin_api_params)

  if err_api ~= nil and type(err_api) == "string" and err_api ~= "" then
    return nil, string.format("there was an error while fetching %s err=%s", fetch.plugin_api_uri, err_api)
  end

  if res_api.status ~= 200 then
    return nil, string.format("there was an error while fetching %s status code %d", fetch.plugin_api_uri, res_api.status)
  end

  return res_api.body, nil
end

return fetch
