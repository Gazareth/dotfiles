local jump_column = require("configs.hydra.atlantis.menu.columns.jump")
local modify_column = require("configs.hydra.atlantis.menu.columns.modify")
local swap_column = require("configs.hydra.atlantis.menu.columns.swap")
local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes

local M = {}

-- Base section order
local function build_default_sections()
  return { jump_column, modify_column, swap_column }
end

-- Modify column title wrapper
local function build_modify_spec(modify_spec)
  return vim.tbl_extend("force", {}, modify_spec, {
    title = " ✦ Modify",
  })
end

-- Parsed anchor targets
local function resolve_anchor_target(parsed)
  if type(parsed) ~= "table" then
    return nil
  end

  local targets = type(parsed.targets) == "table" and parsed.targets or nil
  if type(targets) ~= "table" then
    return nil
  end

  if parsed.node_kind == supported_nodes.fn and type(targets.function_name) == "table" then
    return targets.function_name
  end

  if parsed.node_kind == supported_nodes.assignment and type(targets.left) == "table" then
    return targets.left
  end

  return nil
end

-- Anchor node info with semantic target position
local function build_positioned_anchor(anchor_node_info)
  if type(anchor_node_info) ~= "table" then
    return anchor_node_info
  end

  local parsed = require("configs.hydra.atlantis.treesitter")(anchor_node_info)
  local target = resolve_anchor_target(parsed)
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

-- Atlantis menu structure
function M.build_menu_spec()
  local cursor_node_info = require("configs.hydra.atlantis.treesitter.common.node_info").build_node_info()
  if not cursor_node_info then
    return {
      title = "Treewalker",
      sections = build_default_sections(),
    }
  end

  local select_anchor_node_info = require("configs.hydra.atlantis.treesitter.anchor").select_node_info
  local anchor_node_info = select_anchor_node_info(cursor_node_info)
  local positioned_anchor_node_info = build_positioned_anchor(anchor_node_info)

  local modify_spec = modify_column()
  if type(modify_spec) ~= "table" then
    return {
      title = "Treewalker",
      sections = build_default_sections(),
      anchor_node_info = positioned_anchor_node_info,
    }
  end

  if modify_spec.__abort_open == true then
    return {
      title = "Treewalker",
      sections = { jump_column, modify_spec, swap_column },
      anchor_node_info = positioned_anchor_node_info,
    }
  end

  local menu_title = modify_spec.title or "Treewalker"

  return {
    title = menu_title,
    sections = { jump_column, build_modify_spec(modify_spec), swap_column },
    anchor_node_info = positioned_anchor_node_info,
  }
end

return M