local namu = require("configs.hydra.menus.namu")
local treewalker_scope = require("configs.hydra.menus.treewalker.jump")
local treewalker_context = require("configs.hydra.menus.treewalker.context")
local treewalker_node_action = require("configs.hydra.menus.treewalker.swap")

-- Treewalker menu with semantic title
local function build_treewalker_menu_spec()
  local context_spec = treewalker_context()
  if type(context_spec) ~= "table" then
    return {
      title = "Treewalker",
      sections = { treewalker_scope, treewalker_context, treewalker_node_action },
    }
  end

  if context_spec.__abort_open == true then
    return {
      title = "Treewalker",
      sections = { treewalker_scope, context_spec, treewalker_node_action },
    }
  end

  local menu_title = context_spec.title or "Treewalker"
  local modify_spec = vim.tbl_extend("force", {}, context_spec, {
    title = " ✦ Modify",
  })

  return {
    title = menu_title,
    sections = { treewalker_scope, modify_spec, treewalker_node_action },
  }
end

return {
  namu_all = {
    title = "Namu",
    sections = { namu.symbols, namu.diagnostics, namu.call_hierarchy },
  },
  treewalker_all = build_treewalker_menu_spec,
}
