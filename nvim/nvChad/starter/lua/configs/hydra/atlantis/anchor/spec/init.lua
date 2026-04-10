-- Build render spec from capability payload so menu rendering stays data-only
local title_builder = require("configs.hydra.atlantis.menu.components.title.builder")
local action_rows = require("configs.hydra.atlantis.menu.components.action.rows")
local action_order = require("configs.hydra.atlantis.anchor.spec.action_order")

local M = {}

-- Build fully-resolved render spec with title and pre-built action rows
function M.build(node_info, parsed, capabilities)
  local node_kind = type(capabilities) == "table" and capabilities.node_kind or nil
  local ordered_action_names = action_order.build(node_kind)

  local resolved_action_rows = action_rows.build_rows(node_kind, ordered_action_names, {
    ctx = { node_info = node_info, parsed = parsed },
    capabilities = capabilities,
  })

  return {
    title = title_builder.build_from_parsed(node_info, parsed),
    action_rows = resolved_action_rows,
    action_ids = type(capabilities) == "table" and capabilities.action_ids or nil,
  }
end

return M
