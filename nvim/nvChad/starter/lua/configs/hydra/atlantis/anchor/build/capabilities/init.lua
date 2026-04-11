local jump_to_relative = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative")
local menu_labels = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels")
local probe = require("configs.hydra.atlantis.anchor.probe")

local M = {}

-- Fill anchor payload with parsed anchor data and jump metadata
function M.fill(anchor_node_info, cursor_node_info, depth, find_result)
  local parsed_anchor = probe.parse(anchor_node_info)
  local candidates = type(find_result) == "table" and find_result.candidates or {}
  local selected_index = type(find_result) == "table" and find_result.selected_candidate_index or nil

  -- Same indices as `candidates`: short quoted name for Hydra (e.g. `"foo"`). Used for context
  -- higher/lower rows; parent/sibling rows label themselves via relative_jumps.
  local jump_labels = {}
  for i, c in ipairs(candidates) do
    if type(c) == "table" and type(c.node_info) == "table" then
      jump_labels[i] = menu_labels.quoted_target(c.node_info, probe.parse(c.node_info))
    end
  end

  local jump_spec = jump_to_relative.build(anchor_node_info, {
    candidates = candidates,
    selected_candidate_index = selected_index,
    jump_labels = jump_labels,
  })

  return {
    parsed_anchor = parsed_anchor,
    jump_candidates = candidates,
    selected_jump_candidate_index = selected_index,
    jump_spec = jump_spec,
  }
end

return M
