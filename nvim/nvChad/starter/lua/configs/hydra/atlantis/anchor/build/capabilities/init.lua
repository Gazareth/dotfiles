local jump_to_relative = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative")
local probe = require("configs.hydra.atlantis.anchor.probe")

local M = {}

-- Fill anchor payload with parsed anchor data and jump metadata
function M.fill(anchor_node_info, find_result)
  find_result = type(find_result) == "table" and find_result or {}
  local candidates = find_result.candidates or {}
  local idx = find_result.selected_candidate_index
  local entry = type(idx) == "number" and candidates[idx] or nil
  local parsed_anchor = type(entry) == "table" and type(entry.parsed) == "table" and entry.parsed or nil
  if not parsed_anchor then
    parsed_anchor = probe.parse(anchor_node_info)
  end
  return {
    parsed_anchor = parsed_anchor,
    jump_candidates = candidates,
    selected_jump_candidate_index = idx,
    jump_spec = jump_to_relative.build(anchor_node_info, find_result),
  }
end

return M
