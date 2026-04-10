local treesitter_config = require("configs.hydra.atlantis.anchor.probe.treesitter.config")
local candidates = require("configs.hydra.atlantis.anchor.build.find_from_node.candidates")
local selection = require("configs.hydra.atlantis.anchor.build.find_from_node.selection")

local M = {}

-- Build step result with anchor node, candidate chain, and selected chain index
function M.find(node_info, depth)
  if not node_info or not node_info.node then
    return {
      anchor_node_info = node_info,
      candidates = {},
      selected_candidate_index = nil,
    }
  end

  local config = treesitter_config.get()
  local resolved_depth = type(depth) == "number" and depth or config.depth or 0
  local candidate_chain = candidates.collect(node_info, config)

  if #candidate_chain == 0 then
    return {
      anchor_node_info = node_info,
      candidates = candidate_chain,
      selected_candidate_index = nil,
    }
  end

  local anchor_node_info = selection.select_anchor_node_info(candidate_chain, resolved_depth)
  local selected_candidate_index = selection.find_candidate_index(candidate_chain, anchor_node_info)

  return {
    anchor_node_info = anchor_node_info,
    candidates = candidate_chain,
    selected_candidate_index = selected_candidate_index,
  }
end

return M
