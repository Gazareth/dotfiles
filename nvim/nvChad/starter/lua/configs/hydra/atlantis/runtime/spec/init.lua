-- Build render spec from capability payload so menu rendering stays data-only
local title_builder = require("configs.hydra.atlantis.menu.components.title")
local action_rows = require("configs.hydra.atlantis.menu.components.action.rows")
local action_order = require("configs.hydra.atlantis.runtime.spec.action_order")
local submenu_rows = require("configs.hydra.atlantis.runtime.spec.submenu_rows")

local M = {}

-- Collect already-used row keys to avoid submenu key collisions
local function collect_used_keys(rows)
  local used = {}
  for _, row in ipairs(rows or {}) do
    if type(row) == "table" and type(row.key) == "string" and row.key ~= "" then
      used[string.lower(row.key)] = true
    end
  end
  return used
end

-- Build fully-resolved render spec: title, pre-built action rows, and submenu rows
function M.build(node_info, parsed, capabilities)
  local node_kind = type(capabilities) == "table" and capabilities.node_kind or nil
  local ordered_action_names = action_order.build(node_kind)

  local resolved_action_rows = action_rows.build_rows(node_kind, ordered_action_names, {
    ctx = { node_info = node_info, parsed = parsed },
    capabilities = capabilities,
  })

  local used_keys = collect_used_keys(resolved_action_rows)
  local resolved_submenu_rows = submenu_rows.build(capabilities, used_keys)

  return {
    title = title_builder.build_from_parsed(node_info, parsed),
    action_rows = resolved_action_rows,
    submenu_rows = resolved_submenu_rows,
    action_ids = type(capabilities) == "table" and capabilities.action_ids or nil,
  }
end

return M
