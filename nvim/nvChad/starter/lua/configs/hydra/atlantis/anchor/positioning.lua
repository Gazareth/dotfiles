-- Resolve preferred cursor anchor position for menu open behavior
local treesitter_constants = require("configs.hydra.atlantis.anchor.probe.treesitter.constants")

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
function M.build_positioned_anchor(anchor_node_info, parsed_anchor)
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

return M
