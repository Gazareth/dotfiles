local anchor_actionable = require("configs.hydra.atlantis.prepare.anchor_point.build.actionable")
local find_result = require("configs.hydra.atlantis.prepare.anchor_point.build.find_from_node.find_result")
local build_node_info = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.node_info").build_node_info
local probe = require("configs.hydra.atlantis.prepare.anchor_point.probe")
local treesitter_config = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.config")

local M = {}

-- Collect potential "anchor" candidate nodes from cursor node to root
function M.collect(node_info, config)
  local cfg = type(config) == "table" and config or treesitter_config.get()
  local current = node_info and node_info.node or nil
  local candidate_chain = {}
  local resolve_options = anchor_actionable.resolve_options_from_config(cfg)

  while current do
    local candidate = build_node_info({
      bufnr = node_info.bufnr,
      node = current,
    })

    local is_actionable, semantic = false, nil
    if candidate then
      is_actionable, semantic = anchor_actionable.check(candidate, resolve_options)
    end

    if candidate and is_actionable then
      candidate_chain[#candidate_chain + 1] = find_result.candidate(
        candidate,
        semantic,
        probe.parse(candidate, { semantic = semantic, config = cfg })
      )
    end

    current = current:parent()
  end

  return candidate_chain
end

return M