local node_capabilities = require("configs.hydra.atlantis.registry.node_capabilities")
local spec_builder = require("configs.hydra.atlantis.anchor.spec")

local M = {}

-- Build action adapters and render spec from parsed anchor payload
function M.build(anchor_node_info, parsed_anchor, cursor_node_info, depth_mode)
  local capabilities = node_capabilities.build(parsed_anchor and parsed_anchor.node_kind, {
    node_info = anchor_node_info,
    parsed = parsed_anchor,
    cursor_node_info = cursor_node_info,
    depth_mode = depth_mode,
  })

  local render_spec = spec_builder.build(anchor_node_info, parsed_anchor, capabilities)

  return {
    capabilities = capabilities,
    render_spec = render_spec,
  }
end

return M
