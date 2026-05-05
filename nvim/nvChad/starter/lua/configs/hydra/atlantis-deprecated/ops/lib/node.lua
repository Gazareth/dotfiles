-- Shared node label and placeholder helpers for action messaging
local M = {}

-- Resolve label from action context payload
function M.resolve_node_label(ctx)
  local parsed = type(ctx) == "table" and ctx.parsed or nil
  local node_info = type(ctx) == "table" and ctx.node_info or nil

  return (parsed and parsed.display_name)
    or (parsed and parsed.node_type)
    or (node_info and node_info.node_type)
    or "node"
end

-- Build placeholder closure for unimplemented actions
function M.placeholder(verb, label)
  return function()
    vim.notify(verb .. " " .. label .. " is not implemented yet.", vim.log.levels.INFO)
  end
end

return M
