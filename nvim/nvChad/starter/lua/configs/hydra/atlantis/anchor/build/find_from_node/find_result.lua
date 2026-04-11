-- Shape of `find_from_node.find` return value (and `capabilities.fill` / `jump_to_relative.build` input).
--
--   anchor_node_info   — chosen anchor (node_info) for this menu open
--   candidates         — array of candidate entries (parent chain, actionable only), root = index 1
--   selected_candidate_index — 1-based index into `candidates` matching `anchor_node_info`, or nil
--
-- Each candidate entry (see `M.candidate`):
--   node_info  — build_node_info payload
--   semantic   — languages.resolve row (actionable anchors only)
--   parsed     — probe.parse(node_info, { semantic, config }) reusing languages.resolve from check

local M = {}

function M.candidate(node_info, semantic, parsed)
  return {
    node_info = node_info,
    semantic = semantic,
    parsed = parsed,
  }
end

function M.pack(anchor_node_info, candidates, selected_candidate_index)
  return {
    anchor_node_info = anchor_node_info,
    candidates = candidates or {},
    selected_candidate_index = selected_candidate_index,
  }
end

return M
