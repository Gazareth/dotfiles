local function resolve(choice)
  if choice.module and choice.fn then
    local ok, mod = pcall(require, "namu." .. choice.module)
    if not ok then
      vim.notify("Failed to load Namu module: namu." .. choice.module, vim.log.levels.ERROR)
      return
    end

    local fn = mod[choice.fn]
    if type(fn) ~= "function" then
      vim.notify("Namu menu item is missing function: " .. choice.fn, vim.log.levels.ERROR)
      return
    end

    fn()
  end
end

return {
  id = "namu",
  prompt = "Namu Features",
  items = {
    { label = "Diagnostics: Buffer", module = "namu_diagnostics", fn = "show_current_diagnostics" },
    { label = "Diagnostics: Open", module = "namu_diagnostics", fn = "show_buffer_diagnostics" },
    { label = "Diagnostics: Workspace", module = "namu_diagnostics", fn = "show_workspace_diagnostics" },
    { label = "Symbols: Buffer", module = "namu_symbols", fn = "show" },
    { label = "Calls: Incoming", module = "namu_callhierarchy", fn = "show_incoming_calls" },
    { label = "Calls: Outgoing", module = "namu_callhierarchy", fn = "show_outgoing_calls" },
    { label = "Calls: Both", module = "namu_callhierarchy", fn = "show_both_calls" },
  },
  resolve = resolve,
}
