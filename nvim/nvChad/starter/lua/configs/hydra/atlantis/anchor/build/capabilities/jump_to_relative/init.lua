local menu_schema = require("configs.hydra.atlantis.schema.menu")
local rows = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.rows")

local M = {}

function M.build(anchor_node_info, find_result)
  return {
    title = menu_schema.jump.title,
    items = rows.build_items(anchor_node_info, find_result),
  }
end

return M
