local build_node_info = require("configs.hydra.atlantis.anchor.probe.treesitter.node_info").build_node_info
local find_from_node = require("configs.hydra.atlantis.anchor.build.find_from_node")
local capabilities = require("configs.hydra.atlantis.anchor.build.capabilities")
local cursor_offset = require("configs.hydra.atlantis.anchor.build.cursor_offset")
local get_build_status = require("configs.hydra.atlantis.anchor.build.get_build_status")

local M = {}

-- Build single anchor payload from cursor, depth, probe, and anchor heuristics
function M.build(opts)
  local depth = type(opts) == "table" and opts.depth or nil
  local cursor_node_info = build_node_info()
  if not cursor_node_info then
    return {
      depth = depth,
      cursor_node_info = nil,
      anchor_node_info = nil,
      positioned_anchor_node_info = nil,
      parsed_anchor = nil,
    }
  end

  -- Step 1: Find anchor node from cursor location and depth
  local found = find_from_node.find(cursor_node_info, depth)
  local anchor_node_info = found.anchor_node_info

  -- Step 2: Fill anchor payload with parsed data and jump candidates
  local filled = capabilities.fill(anchor_node_info, cursor_node_info, depth, found)
  local parsed_anchor = filled.parsed_anchor

  -- Step 3: Surface semantic build status for unknown nodes or disabled languages
  get_build_status.notify(parsed_anchor)

  -- Step 4: Offset cursor start to the preferred semantic target inside anchor
  local positioned_anchor_node_info = cursor_offset.build_positioned_anchor(anchor_node_info, parsed_anchor)

  return {
    depth = depth,
    cursor_node_info = cursor_node_info,
    anchor_node_info = anchor_node_info,
    positioned_anchor_node_info = positioned_anchor_node_info,
    parsed_anchor = parsed_anchor,
    jump_candidates = found.candidates,
    selected_jump_candidate_index = found.selected_candidate_index,
    jump_spec = filled.jump_spec,
  }
end

return M
