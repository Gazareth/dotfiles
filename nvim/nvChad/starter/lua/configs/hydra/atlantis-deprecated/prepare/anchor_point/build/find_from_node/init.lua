local candidates = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.find_from_node.candidates")
local find_result = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.find_from_node.find_result")
local selection = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.build.find_from_node.selection")
local treesitter_config = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.treesitter.config")

local M = {}

-- Build step result with anchor node, candidate chain, and selected chain index (see find_result.lua).
function M.find(node_info, depth)
  if not node_info or not node_info.node then
    return find_result.pack(node_info, {}, nil)
  end

  local config = treesitter_config.get()
  local resolved_depth = type(depth) == "number" and depth or config.depth or 0
  local candidate_chain = candidates.collect(node_info, config)

  if #candidate_chain == 0 then
    return find_result.pack(node_info, candidate_chain, nil)
  end

  local anchor_node_info = selection.select_anchor_node_info(candidate_chain, resolved_depth)
  local selected_candidate_index = selection.find_candidate_index(candidate_chain, anchor_node_info)

  return find_result.pack(anchor_node_info, candidate_chain, selected_candidate_index)
end

return M
