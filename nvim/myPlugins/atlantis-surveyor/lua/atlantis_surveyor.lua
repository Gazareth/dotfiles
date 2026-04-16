--- Thin loader: native module lives in lua/native/ (see build.ps1 / build.sh).
local function plugin_root()
  local s = debug.getinfo(1, "S").source
  if s:sub(1, 1) == "@" then
    s = s:sub(2)
  end
  return vim.fn.fnamemodify(s, ":p:h:h")
end

local ext = vim.fn.has("win32") == 1 and "dll" or "so"
local lib = vim.fs.joinpath(plugin_root(), "lua", "native", "atlantis_surveyor." .. ext)

local loadfn, err = package.loadlib(lib, "luaopen_atlantis_surveyor")
if not loadfn then
  error(("[atlantis_surveyor] could not load %s: %s"):format(lib, err or "?"))
end

return loadfn()
