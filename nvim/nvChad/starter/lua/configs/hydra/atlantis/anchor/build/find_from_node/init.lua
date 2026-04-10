local treesitter_config = require("configs.hydra.atlantis.anchor.probe.treesitter.config")
local candidate_chain = require("configs.hydra.atlantis.anchor.build.find_from_node.candidates")
local scoring = require("configs.hydra.atlantis.anchor.build.find_from_node.scoring")

local M = {}

-- Build step result with anchor node, candidate chain, and selected chain index
function M.find(node_info, mode)
  if not node_info or not node_info.node then
    return {
      anchor_node_info = node_info,
      candidates = {},
      selected_candidate_index = nil,
    }
  end

  local config = treesitter_config.get()
  local resolved_mode = mode or config.context_mode or "depth_0"
  local candidates = candidate_chain.get_candidates(node_info)

  if #candidates == 0 then
    return {
      anchor_node_info = node_info,
      candidates = candidates,
      selected_candidate_index = nil,
    }
  end

  local anchor_node_info = scoring.select_by_mode(candidates, resolved_mode)
  local selected_candidate_index = candidate_chain.find_candidate_index(candidates, anchor_node_info)

  return {
    anchor_node_info = anchor_node_info,
    candidates = candidates,
    selected_candidate_index = selected_candidate_index,
  }
end

return M
