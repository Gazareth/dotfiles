local M = {}

-- Build the rename action for the current symbol.
function M.build_change_name_action()
  return function()
    local ok, err = pcall(vim.lsp.buf.rename)
    if not ok then
      vim.notify("Rename is unavailable: " .. tostring(err), vim.log.levels.WARN)
    end
  end
end

-- Build the action that opens call hierarchy when available.
function M.build_call_hierarchy_action()
  return function()
    local ok_mod, mod = pcall(require, "namu.namu_callhierarchy")
    if ok_mod and type(mod.show_both_calls) == "function" then
      mod.show_both_calls()
      return
    end

    vim.notify("Call hierarchy provider is unavailable.", vim.log.levels.WARN)
  end
end

return M
