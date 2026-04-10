local build_node_info = require("configs.hydra.atlantis.anchor.probe.treesitter.node_info").build_node_info
local selector = require("configs.hydra.atlantis.anchor.selector")
local probe = require("configs.hydra.atlantis.anchor.probe")
local node_capabilities = require("configs.hydra.atlantis.registry.node_capabilities")
local spec_builder = require("configs.hydra.atlantis.anchor.spec")
local positioning = require("configs.hydra.atlantis.anchor.positioning")
local semantic_status = require("configs.hydra.atlantis.anchor.semantic_status")

local M = {}

-- Build single anchor payload from cursor, depth mode, probe, and capabilities
function M.build(opts)
  local depth_mode = type(opts) == "table" and opts.depth_mode or nil
  local cursor_node_info = build_node_info()
  if not cursor_node_info then
    return {
      depth_mode = depth_mode,
      cursor_node_info = nil,
      anchor_node_info = nil,
      positioned_anchor_node_info = nil,
      parsed_anchor = nil,
      capabilities = nil,
      render_spec = nil,
    }
  end

  local anchor_node_info = selector.select_node_info(cursor_node_info, depth_mode)
  local parsed_anchor = probe.parse(anchor_node_info)
  local positioned_anchor_node_info = positioning.build_positioned_anchor(anchor_node_info, parsed_anchor)
  local capabilities = node_capabilities.build(parsed_anchor and parsed_anchor.node_kind, {
    node_info = anchor_node_info,
    parsed = parsed_anchor,
    cursor_node_info = cursor_node_info,
    depth_mode = depth_mode,
  })

  semantic_status.notify(parsed_anchor)
  local render_spec = spec_builder.build(anchor_node_info, parsed_anchor, capabilities)

  return {
    depth_mode = depth_mode,
    cursor_node_info = cursor_node_info,
    anchor_node_info = anchor_node_info,
    positioned_anchor_node_info = positioned_anchor_node_info,
    parsed_anchor = parsed_anchor,
    capabilities = capabilities,
    render_spec = render_spec,
  }
end

-- Select anchor node from cursor location and depth mode
function M.select_node_info(node_info, mode)
  return selector.select_node_info(node_info, mode)
end

-- Return actionable anchor candidates for debug and jump sections
function M.get_candidates(node_info)
  return selector.get_candidates(node_info)
end

-- Find selected anchor index inside actionable candidate list
function M.find_candidate_index(candidates, selected_node_info)
  return selector.find_candidate_index(candidates, selected_node_info)
end

return M
