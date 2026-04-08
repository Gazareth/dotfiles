local jump_column = require("configs.hydra.atlantis.menu.columns.jump")
local modify_column = require("configs.hydra.atlantis.menu.columns.modify")
local swap_column = require("configs.hydra.atlantis.menu.columns.swap")

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

  local modify_spec = modify_column()
  if type(modify_spec) ~= "table" then
    return {
      title = "Treewalker",
      sections = build_default_sections(),
      anchor_node_info = anchor_node_info,
    }
  end

  if modify_spec.__abort_open == true then
    return {
      title = "Treewalker",
      sections = { jump_column, modify_spec, swap_column },
      anchor_node_info = anchor_node_info,
    }
  end

  local menu_title = modify_spec.title or "Treewalker"

  return {
    title = menu_title,
    sections = { jump_column, build_modify_spec(modify_spec), swap_column },
    anchor_node_info = anchor_node_info,
  }
end

return M