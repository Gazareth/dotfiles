local M = {}

local _lazy_plugins = nil
local function lazy_plugins()
  if _lazy_plugins == nil then
    local ok, lc = pcall(require, "lazy.core.config")
    _lazy_plugins = (ok and lc.plugins) or {}
  end
  return _lazy_plugins
end

-- Returns true if `mod_name` can be required, or if lazy.nvim knows `lazy_name`.
function M.has(mod_name, lazy_name)
  if pcall(require, mod_name) then return true end
  return lazy_plugins()[lazy_name] ~= nil
end

-- vim-exchange uses a Vimscript global rather than a Lua module.
function M.has_exchange()
  return vim.fn.exists("g:loaded_exchange") == 1 or lazy_plugins()["vim-exchange"] ~= nil
end

return M
