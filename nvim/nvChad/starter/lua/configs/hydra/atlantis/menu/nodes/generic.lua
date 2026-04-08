local M = {}
local title_builder = require("configs.hydra.atlantis.menu.title")
local common_actions = require("configs.hydra.atlantis.menu.actions.common")
local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes

-- Fallback menu for unsupported node kinds
function M.build(node_info, parsed)
  local label = (parsed and parsed.display_name) or (node_info and node_info.node_type) or "node"
  -- Shared generic action rows
  local generic_rows = common_actions.build_generic_action_rows(supported_nodes.generic, label, {
    node_info = node_info,
    parsed = parsed,
  })
  local items = {
    {
      heading = "Actions",
    },
    {
      separator = true,
    },
  }

  for _, row in ipairs(generic_rows) do
    items[#items + 1] = row
  end

  -- Basic actions for fallback menus
  return {
    title = title_builder.build_from_parsed(node_info, parsed),
    items = items,
  }
end

return M
