--- Thin loader: native module lives in lua/native/ (see build.ps1 / build.sh).
local function plugin_root()
  local s = debug.getinfo(1, "S").source
  if s:sub(1, 1) == "@" then
    s = s:sub(2)
  end
  return vim.fn.fnamemodify(s, ":p:h:h")
end

local ext = vim.fn.has("win32") == 1 and "dll" or "so"
local root = plugin_root()

local paths_to_try = {
  vim.fs.joinpath(root, "target", "debug", "atlantis_surveyor." .. ext),
  vim.fs.joinpath(root, "target", "release", "atlantis_surveyor." .. ext),
  vim.fs.joinpath(root, "lua", "native", "atlantis_surveyor." .. ext),
}

local newest_lib = nil
local max_mtime = 0

for _, path in ipairs(paths_to_try) do
  local stat = vim.uv.fs_stat(path)
  if stat and stat.type == "file" then
    if stat.mtime.sec > max_mtime then
      max_mtime = stat.mtime.sec
      newest_lib = path
    end
  end
end

if not newest_lib then
  error("[atlantis_surveyor] Could not find compiled library. Run `cargo build`.")
end

local loadfn, err = package.loadlib(newest_lib, "luaopen_atlantis_surveyor")
if not loadfn then
  error(("[atlantis_surveyor] could not load %s: %s"):format(newest_lib, err or "?"))
end

return loadfn()
