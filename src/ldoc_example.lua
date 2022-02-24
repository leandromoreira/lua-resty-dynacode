--- Load a local or remote manifest describing a repository.
-- All functions that use manifest tables assume they were obtained
-- through either this function or load_local_manifest.
-- @param repo_url string: URL or pathname for the repository.
-- @param lua_version string: Lua version in "5.x" format, defaults to installed version.
-- @return table or (nil, string, [string]): A table representing the manifest,
-- or nil followed by an error message and an optional error code.
function manif.load_manifest(repo_url, lua_version)
   -- code
end
