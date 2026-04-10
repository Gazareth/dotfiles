local probe = require("configs.hydra.atlantis.anchor.probe")
local action_adapters = require("configs.hydra.atlantis.anchor.build.capabilities.action_adapters")
local jump_section = require("configs.hydra.atlantis.anchor.build.capabilities.jump_section")

local M = {}

-- Fill anchor payload with parsed data, jump candidates, and menu adapters
function M.fill(anchor_node_info, cursor_node_info, depth_mode, find_result)
  local parsed_anchor = probe.parse(anchor_node_info)
  local candidates = type(find_result) == "table" and find_result.candidates or {}
  local selected_index = type(find_result) == "table" and find_result.selected_candidate_index or nil

  local adapters = action_adapters.build(anchor_node_info, parsed_anchor, cursor_node_info, depth_mode)
  local jump_spec = jump_section.build(anchor_node_info, {
    candidates = candidates,
    selected_candidate_index = selected_index,
  })

  return {
    parsed_anchor = parsed_anchor,
    jump_candidates = candidates,
    selected_jump_candidate_index = selected_index,
    jump_spec = jump_spec,
    capabilities = adapters.capabilities,
    render_spec = adapters.render_spec,
  }
end

return M
