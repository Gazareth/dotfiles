local M = {}

-- Rename action from function context
function M.change_name(_ctx)
  return function()
    local ok, err = pcall(vim.lsp.buf.rename)
    if not ok then
      vim.notify("Rename is unavailable: " .. tostring(err), vim.log.levels.WARN)
    end
  end
end

-- Call hierarchy action from function context
function M.view_call_hierarchy(_ctx)
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
