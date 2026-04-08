local treewalker_scope = require("configs.hydra.atlantis.treewalker.jump")
local treewalker_context = require("configs.hydra.atlantis.treewalker.context")
local treewalker_node_action = require("configs.hydra.atlantis.treewalker.swap")

local M = {}

-- Base section order
local function build_default_sections()
  return { treewalker_scope, treewalker_context, treewalker_node_action }
end

-- Context section with modify title
local function build_modify_spec(context_spec)
  return vim.tbl_extend("force", {}, context_spec, {
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

  local context_spec = treewalker_context()
  if type(context_spec) ~= "table" then
    return {
      title = "Treewalker",
      sections = build_default_sections(),
      anchor_node_info = anchor_node_info,
    }
  end

  if context_spec.__abort_open == true then
    return {
      title = "Treewalker",
      sections = { treewalker_scope, context_spec, treewalker_node_action },
      anchor_node_info = anchor_node_info,
    }
  end

  local menu_title = context_spec.title or "Treewalker"

  return {
    title = menu_title,
    sections = { treewalker_scope, build_modify_spec(context_spec), treewalker_node_action },
    anchor_node_info = anchor_node_info,
  }
end

return M