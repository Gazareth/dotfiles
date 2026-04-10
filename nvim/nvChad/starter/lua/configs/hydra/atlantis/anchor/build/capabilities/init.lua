local probe = require("configs.hydra.atlantis.anchor.probe")
local node_capabilities = require("configs.hydra.atlantis.node_capabilities")
local spec_builder = require("configs.hydra.atlantis.anchor.spec")
local jump_section = require("configs.hydra.atlantis.anchor.build.capabilities.jump_section")

local M = {}

-- Fill anchor payload with parsed data, jump candidates, and menu adapters
function M.fill(anchor_node_info, cursor_node_info, depth, find_result)
  local parsed_anchor = probe.parse(anchor_node_info)
  local candidates = type(find_result) == "table" and find_result.candidates or {}
  local selected_index = type(find_result) == "table" and find_result.selected_candidate_index or nil
  local capabilities = node_capabilities.build(parsed_anchor and parsed_anchor.node_kind, {
    node_info = anchor_node_info,
    parsed = parsed_anchor,
    cursor_node_info = cursor_node_info,
    depth = depth,
  })
  local render_spec = spec_builder.build(anchor_node_info, parsed_anchor, capabilities)

  local jump_spec = jump_section.build(anchor_node_info, {
    candidates = candidates,
    selected_candidate_index = selected_index,
  })

  return {
    parsed_anchor = parsed_anchor,
    jump_candidates = candidates,
    selected_jump_candidate_index = selected_index,
    jump_spec = jump_spec,
    capabilities = capabilities,
    render_spec = render_spec,
  }
end

return M
