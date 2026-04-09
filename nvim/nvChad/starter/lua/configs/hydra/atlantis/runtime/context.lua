local build_node_info = require("configs.hydra.atlantis.treesitter.common.node_info").build_node_info
local anchor = require("configs.hydra.atlantis.treesitter.anchor")
local parse_node = require("configs.hydra.atlantis.treesitter")
local node_capabilities = require("configs.hydra.atlantis.registry.node_capabilities")
local treesitter_constants = require("configs.hydra.atlantis.treesitter.common.constants")

local supported_nodes = treesitter_constants.supported_nodes
local parameter_container_types = treesitter_constants.parameter_container_types

local M = {}

-- Resolve preferred jump target within selected anchor
local function resolve_anchor_target(parsed, anchor_node_info)
  if type(parsed) ~= "table" then
    return nil
  end

  local targets = type(parsed.targets) == "table" and parsed.targets or nil

  if parsed.node_kind == supported_nodes.fn and type(targets) == "table" and type(targets.function_name) == "table" then
    return targets.function_name
  end

  if parsed.node_kind == supported_nodes.assignment and type(targets) == "table" and type(targets.left) == "table" then
    return targets.left
  end

  if type(anchor_node_info) == "table"
    and anchor_node_info.node
    and parameter_container_types[anchor_node_info.node_type] == true then
    local first_named = anchor_node_info.node:named_child(0)
    if first_named then
      local row, col = first_named:start()
      return {
        row = row,
        col = col,
      }
    end
  end

  return nil
end

-- Clone anchor info with cursor start aligned to preferred target
local function build_positioned_anchor(anchor_node_info, parsed_anchor)
  if type(anchor_node_info) ~= "table" then
    return anchor_node_info
  end

  local target = resolve_anchor_target(parsed_anchor, anchor_node_info)
  if type(target) ~= "table" then
    return anchor_node_info
  end

  local positioned = vim.tbl_extend("force", {}, anchor_node_info)
  if type(target.row) == "number" then
    positioned.start_row = target.row
  end
  if type(target.col) == "number" then
    positioned.start_col = target.col
  end

  return positioned
end

-- Build single runtime payload for anchor, parse, and capabilities
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
    }
  end

  local anchor_node_info = anchor.select_node_info(cursor_node_info, depth_mode)
  local parsed_anchor = parse_node(anchor_node_info)
  local positioned_anchor_node_info = build_positioned_anchor(anchor_node_info, parsed_anchor)
  local capabilities = node_capabilities.build(parsed_anchor and parsed_anchor.node_kind, {
    node_info = anchor_node_info,
    parsed = parsed_anchor,
    cursor_node_info = cursor_node_info,
    depth_mode = depth_mode,
  })

  return {
    depth_mode = depth_mode,
    cursor_node_info = cursor_node_info,
    anchor_node_info = anchor_node_info,
    positioned_anchor_node_info = positioned_anchor_node_info,
    parsed_anchor = parsed_anchor,
    capabilities = capabilities,
  }
end

return M