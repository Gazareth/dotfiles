local M = {}

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
