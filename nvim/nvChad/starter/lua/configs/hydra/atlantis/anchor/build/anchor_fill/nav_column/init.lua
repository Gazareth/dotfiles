local menu_labels = require("configs.hydra.atlantis.anchor.build.anchor_fill.nav_column.labels")
local column_titles = require("configs.hydra.atlantis.menu.column_titles")
local menu_schema = require("configs.hydra.atlantis.schema.menu")
local rows = require("configs.hydra.atlantis.anchor.build.anchor_fill.nav_column.rows")

local jump_section = {}

function jump_section.build(anchor_node_info, find_result, menu_opts)
  find_result = type(find_result) == "table" and find_result or {}
  local jump_ctx = {
    candidates = find_result.candidates or {},
    selected_candidate_index = find_result.selected_candidate_index,
    jump_labels = menu_labels.jump_labels_for_candidates(find_result.candidates),
  }
  return {
    title = column_titles.navigate(),
    items = rows.build_items(anchor_node_info, jump_ctx, menu_opts),
  }
end

return jump_section
