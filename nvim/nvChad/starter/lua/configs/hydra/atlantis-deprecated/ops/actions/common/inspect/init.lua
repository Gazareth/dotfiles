-- Build inspect action from parsed semantic payload
local lib = require("configs.hydra.atlantis-deprecated.ops.lib.actions")

local M = {}

-- Build inspect closure for debugging semantic parse output
function M.build(ctx)
  return function()
    local node_info = type(ctx) == "table" and ctx.node_info or nil
    local parsed = type(ctx) == "table" and ctx.parsed or nil
    local semantic = parsed and parsed.semantic or {}
    local node_label = lib.resolve_node_label(ctx)

    local message = table.concat({
      "Atlantis node inspect [" .. node_label .. "]:",
      "node_type=" .. tostring((parsed and parsed.node_type) or (node_info and node_info.node_type)),
      "tier=" .. tostring(parsed and parsed.node_tier),
      "kind=" .. tostring(parsed and parsed.semantic_kind),
      "actionable=" .. tostring(parsed and parsed.actionable),
      "status=" .. tostring(semantic.status),
    }, " ")

    vim.notify(message, vim.log.levels.INFO)
  end
end

return M
