-- Build runtime context payload for menu rendering from cursor, anchor, parse, and capabilities
local build_node_info = require("configs.hydra.atlantis.treesitter.common.node_info").build_node_info
local anchor = require("configs.hydra.atlantis.treesitter.anchor")
local parse_node = require("configs.hydra.atlantis.treesitter")
local node_capabilities = require("configs.hydra.atlantis.registry.node_capabilities")
local spec_builder = require("configs.hydra.atlantis.runtime.spec")
local positioning = require("configs.hydra.atlantis.runtime.context.positioning")
local semantic_status = require("configs.hydra.atlantis.runtime.context.semantic_status")

local M = {}

-- Build single runtime payload for anchor, parse, capabilities, and render spec
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

  local anchor_node_info = anchor.select_node_info(cursor_node_info, depth_mode)
  local parsed_anchor = parse_node(anchor_node_info)
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

return M
