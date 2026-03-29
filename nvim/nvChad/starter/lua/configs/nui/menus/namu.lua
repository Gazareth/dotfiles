local module_name = "namu"

local items = {
  { key = "b", icon = "", label = "Buffer diagnostics", submodule = "namu_diagnostics", fn = "show_current_diagnostics" },
  { key = "o", icon = "", label = "Open-buffer diagnostics", submodule = "namu_diagnostics", fn = "show_buffer_diagnostics" },
  { key = "w", icon = "", label = "Workspace diagnostics", submodule = "namu_diagnostics", fn = "show_workspace_diagnostics" },
  { key = "s", icon = "", label = "Buffer symbols", submodule = "namu_symbols", fn = "show" },
  { key = "i", icon = "", label = "Incoming calls", submodule = "namu_callhierarchy", fn = "show_incoming_calls" },
  { key = "g", icon = "", label = "Outgoing calls", submodule = "namu_callhierarchy", fn = "show_outgoing_calls" },
  { key = "c", icon = "", label = "All calls (in & out)", submodule = "namu_callhierarchy", fn = "show_both_calls" },
}

return vim.tbl_map(function(item)
  return vim.tbl_extend("force", {
    module = module_name,
  }, item)
end, items)
