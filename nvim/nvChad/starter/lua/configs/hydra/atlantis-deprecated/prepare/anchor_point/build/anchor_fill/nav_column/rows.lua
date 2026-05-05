local menu_schema = require("configs.hydra.atlantis-deprecated.schema.menu")
local relative_jumps = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.anchor_fill.nav_column.sibling_jumps")
local navigation_rows = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.anchor_fill.nav_column.navigation_rows")
local relation_rows = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.anchor_fill.nav_column.relation_rows")
local anchor_actionable = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.actionable")
local build_node_info = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.treesitter.node_info").build_node_info
local treesitter_config = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.treesitter.config")

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

  -- Pick the innermost candidate whose direct parent is a schema-recognised container.
  -- This gives siblings at the right scope without coupling to tier abstractions.
  local sibling_context = anchor_node_info
  local cfg = treesitter_config.get()
  local resolve_options = anchor_actionable.resolve_options_from_config(cfg)
  for i = 1, #candidates do
    local entry = candidates[i]
    local node = entry.node_info and entry.node_info.node
    if node then
      local parent = node:parent()
      if parent then
        local parent_ni = build_node_info({ bufnr = entry.node_info.bufnr, node = parent })
        if anchor_actionable.is_container(parent_ni, resolve_options) then
          sibling_context = entry.node_info
          break
        end
      end
    end
  end
  local labeled = relative_jumps.labeled(sibling_context, navigate_cfg.items)
  relation_rows.append(items, labeled, anchor_node_info, menu_opts)

  return items
end

return jump_rows
