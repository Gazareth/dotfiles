local jump_to_relative = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative")
local probe = require("configs.hydra.atlantis.anchor.probe")

local M = {}

-- Fill anchor payload with parsed anchor data and navigate menu metadata
--- @param menu_opts table|nil optional; pass through to jump row builder (`_atlantis_container_session` distinguishes nav vs anchor menu)
function M.fill(anchor_node_info, find_result, menu_opts)
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
    navigate_spec = jump_to_relative.build(anchor_node_info, find_result, menu_opts),
  }
end

return M
