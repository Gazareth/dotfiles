local module_name = "namu"

local function with_module(items)
  return vim.tbl_map(function(item)
    return vim.tbl_extend("force", {
      module = module_name,
    }, item)
  end, items)
end

return {
  symbols = {
    title = "󰘦 Symbols",
    items = with_module({
      { key = "s", icon = "", label = "Buffer symbols", submodule = "namu_symbols", fn = "show" },
      { key = "o", icon = "", label = "Open-buffer symbols", submodule = "namu_symbols", fn = "show_buffer_symbols" },
      { key = "w", icon = "", label = "Workspace symbols", submodule = "namu_symbols", fn = "show_workspace_symbols" },
    }),
  },
  diagnostics = {
    title = "󰒡 Diagnostics",
    items = with_module({
      { heading = "Jump" },
      { key = "n", icon = "", label = "Jump to next diagnostic in file", action = "lua vim.diagnostic.jump({ count = 1 })" },
      { key = "p", icon = "", label = "Jump to previous diagnostic in file", action = "lua vim.diagnostic.jump({ count = -1 })" },
      { separator = true },
      { heading = "Scan" },
      { key = "b", icon = "", label = "Buffer diagnostics", submodule = "namu_diagnostics", fn = "show_current_diagnostics" },
      { key = "o", icon = "", label = "Open-buffer diagnostics", submodule = "namu_diagnostics", fn = "show_buffer_diagnostics" },
      { key = "w", icon = "", label = "Workspace diagnostics", submodule = "namu_diagnostics", fn = "show_workspace_diagnostics" },
    }),
  },
  call_hierarchy = {
    title = "󰌗 Call hierarchy",
    items = with_module({
      { key = "i", icon = "↙", label = "Incoming calls", submodule = "namu_callhierarchy", fn = "show_incoming_calls" },
      { key = "g", icon = "↗", label = "Outgoing calls", submodule = "namu_callhierarchy", fn = "show_outgoing_calls" },
      { key = "c", icon = "", label = "All calls (in & out)", submodule = "namu_callhierarchy", fn = "show_both_calls" },
    }),
  },
}
