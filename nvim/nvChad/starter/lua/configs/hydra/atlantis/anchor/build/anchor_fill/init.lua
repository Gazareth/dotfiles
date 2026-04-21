local nav_column = require("configs.hydra.atlantis.anchor.build.anchor_fill.nav_column")
local probe = require("configs.hydra.atlantis.anchor.probe")

local M = {}

-- Fill anchor payload with parsed anchor data and navigate menu metadata
--- @param menu_opts table|nil optional; passed through to nav column builder (container_scope field signals container mode)
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
    candidate_chain = candidates,
    selected_jump_candidate_index = idx,
    nav_column_spec = nav_column.build(anchor_node_info, find_result, menu_opts),
  }
end

return M
