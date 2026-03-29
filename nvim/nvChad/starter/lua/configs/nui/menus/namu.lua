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
  prompt = "Namu",
  items = {
    { key = "b", icon = "", label = "Buffer diagnostics", module = "namu_diagnostics", fn = "show_current_diagnostics" },
    { key = "o", icon = "", label = "Open-buffer diagnostics", module = "namu_diagnostics", fn = "show_buffer_diagnostics" },
    { key = "w", icon = "", label = "Workspace diagnostics", module = "namu_diagnostics", fn = "show_workspace_diagnostics" },
    { key = "s", icon = "", label = "Buffer symbols", module = "namu_symbols", fn = "show" },
    { key = "i", icon = "", label = "Incoming calls", module = "namu_callhierarchy", fn = "show_incoming_calls" },
    { key = "g", icon = "", label = "Outgoing calls", module = "namu_callhierarchy", fn = "show_outgoing_calls" },
    { key = "c", icon = "", label = "All calls (in & out)", module = "namu_callhierarchy", fn = "show_both_calls" },
  },
  resolve = resolve,
}
