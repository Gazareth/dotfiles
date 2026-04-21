local menu_schema = require("configs.hydra.atlantis.schema.menu")
local relative_jumps = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.sibling_jumps")
local navigation_rows = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.navigation_rows")
local relation_rows = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.relation_rows")

local jump_rows = {}

local navigate_cfg = menu_schema.navigate

function jump_rows.build_items(anchor_node_info, find_result, menu_opts)
  local items = {}
  local candidates = type(find_result) == "table" and find_result.candidates or {}
  local selected_index = type(find_result) == "table" and find_result.selected_candidate_index or nil
  local jump_labels = type(find_result) == "table" and find_result.jump_labels or nil

  local nav_only = navigation_rows.append(items, anchor_node_info, menu_opts, candidates, selected_index, jump_labels)
  if nav_only then
    return items
  end

  local labeled = relative_jumps.labeled(anchor_node_info, navigate_cfg.items)
  relation_rows.append(items, labeled, anchor_node_info, menu_opts)

  return items
end

return jump_rows
