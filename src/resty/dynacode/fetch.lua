local http = require "resty.http"
local json = require "cjson"

local fetch = {}

fetch.plugin_api_uri = nil
fetch.plugin_api_pooling_interval = 30
fetch.plugin_api_timeout = 5
fetch.cache_key = "dynacode_response"
fetch.cache = nil

function fetch.logger(msg)
  ngx.log(ngx.ERR, msg)
end

function fetch.fetch_code()
  if not fetch.cache or not fetch.plugin_api_uri then
    fetch.logger("error - the fetcher must have a proper cache and the api uri")
    return
  end
  local _, err, hitlevel = fetch.cache:get(fetch.cache_key, nil, fetch.__fetch_code_callback)

  if err ~= nil and type(err) == "string" and err ~= "" then
    fetch.logger("there was an error while fetching " .. fetch.plugin_api_uri .. " err= " .. err)
    return
  end

  ngx.log(ngx.ERR, "cache hit level = " .. hitlevel)
end

function fetch.__fetch_code_callback()
  local httpc = http.new()
  httpc:set_timeout(fetch.plugin_api_timeout * 1000)
  local res_api, err_api = httpc:request_uri(fetch.plugin_api_uri)

  if err_api ~= nil and type(err_api) == "string" and err_api ~= "" then
    fetch.logger("there was an error while fetching " .. fetch.plugin_api_uri .. " err= " .. err_api)
    return nil, "error"
  end

  if res_api.status ~= 200 then
    fetch.logger("there was an error while fetching status code <> from 200 status code = " .. res_api.status)
    return nil, "error"
  end

  local api_response, err = json.decode(res_api.body)
  if err ~= nil then
    fetch.logger("there was an error while decoding the api response " .. err)
    return nil, "error"
  end
  return api_response, nil
end

return fetch
