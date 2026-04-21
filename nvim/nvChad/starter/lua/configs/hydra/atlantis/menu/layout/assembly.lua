local column_titles = require("configs.hydra.atlantis.menu.column_titles")
local section_order = require("configs.hydra.atlantis.menu.layout.sections")

local menu_assembly = {}

local function build_titled_interact_menu_spec(action_menu_spec)
  return vim.tbl_extend("force", {}, action_menu_spec, {
    title = column_titles.interact(),
  })
end

function menu_assembly.build_without_cursor(nav_column_spec)
  return {
    title = column_titles.hydra_default(),
    sections = section_order.build_default(nav_column_spec),
  }
end

function menu_assembly.build_with_invalid_action_menu(positioned_anchor_node_info, nav_column_spec)
  return {
    title = column_titles.hydra_default(),
    sections = section_order.build_default(nav_column_spec),
    anchor_node_info = positioned_anchor_node_info,
  }
end

function menu_assembly.build_with_abort_action_menu(action_menu_spec, positioned_anchor_node_info, nav_column_spec)
  return {
    title = column_titles.hydra_default(),
    sections = section_order.with_action_menu(build_titled_interact_menu_spec(action_menu_spec), nav_column_spec),
    anchor_node_info = positioned_anchor_node_info,
  }
end

function menu_assembly.build_with_action_menu(action_menu_spec, positioned_anchor_node_info, nav_column_spec)
  local menu_title = action_menu_spec.title or column_titles.hydra_default()

  return {
    title = menu_title,
    sections = section_order.with_action_menu(build_titled_interact_menu_spec(action_menu_spec), nav_column_spec),
    anchor_node_info = positioned_anchor_node_info,
  }
end

return menu_assembly
