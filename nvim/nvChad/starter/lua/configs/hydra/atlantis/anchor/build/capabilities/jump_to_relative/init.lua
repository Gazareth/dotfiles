local menu_labels = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels")
local menu_schema = require("configs.hydra.atlantis.schema.menu")
local rows = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.rows")

local M = {}

function M.build(anchor_node_info, find_result)
  find_result = type(find_result) == "table" and find_result or {}
  local jump_ctx = {
    candidates = find_result.candidates or {},
    selected_candidate_index = find_result.selected_candidate_index,
    jump_labels = menu_labels.jump_labels_for_candidates(find_result.candidates),
  }
  return {
    title = menu_schema.jump.title,
    items = rows.build_items(anchor_node_info, jump_ctx),
  }
end

return M
