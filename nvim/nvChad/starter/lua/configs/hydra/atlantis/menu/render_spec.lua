-- Build render spec from anchor context; menu owns presentation assembly
local title_builder = require("configs.hydra.atlantis.menu.components.title.builder")
local action_rows = require("configs.hydra.atlantis.menu.components.action.rows")
local action_order = require("configs.hydra.atlantis.menu.components.action.order")

local M = {}

-- Build render spec from parsed node_kind and runtime context
function M.build(runtime_ctx)
  local parsed = type(runtime_ctx) == "table" and runtime_ctx.parsed_anchor or nil
  local node_info = type(runtime_ctx) == "table" and runtime_ctx.anchor_node_info or nil
  local node_kind = type(parsed) == "table" and parsed.node_kind or nil
  local ordered_action_names = action_order.build(node_kind)

  local resolved_action_rows = action_rows.build_rows(node_kind, ordered_action_names, {
    ctx = {
      node_info = node_info,
      parsed = parsed,
      cursor_node_info = type(runtime_ctx) == "table" and runtime_ctx.cursor_node_info or nil,
      depth = type(runtime_ctx) == "table" and runtime_ctx.depth or nil,
    },
  })

  return {
    title = title_builder.build_from_parsed(node_info, parsed),
    action_rows = resolved_action_rows,
  }
end

return M
