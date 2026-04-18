-- Assemble final menu payload from context and action menu section result.
-- Each `sections` entry maps to one Hydra hint column (`configs.hydra.lib.hint.build`).
local column_titles = require("configs.hydra.atlantis.menu.column_titles")
local section_order = require("configs.hydra.atlantis.menu.layout.sections")

local menu_assembly = {}

local function build_titled_action_menu_spec(action_menu_spec)
  return vim.tbl_extend("force", {}, action_menu_spec, {
    title = column_titles.action(),
  })
end

-- Build menu payload for empty cursor state
function menu_assembly.build_without_cursor(jump_spec)
  return {
    title = column_titles.hydra_default(),
    sections = section_order.build_default(jump_spec),
  }
end

-- Build menu payload when action menu section failed to produce a table
function menu_assembly.build_with_invalid_action_menu(positioned_anchor_node_info, jump_spec)
  return {
    title = column_titles.hydra_default(),
    sections = section_order.build_default(jump_spec),
    anchor_node_info = positioned_anchor_node_info,
  }
end

-- Build menu payload when action menu section requests abort-open behavior
function menu_assembly.build_with_abort_action_menu(action_menu_spec, positioned_anchor_node_info, jump_spec)
  return {
    title = column_titles.hydra_default(),
    sections = section_order.with_action_menu(build_titled_action_menu_spec(action_menu_spec), jump_spec),
    anchor_node_info = positioned_anchor_node_info,
  }
end

-- Build normal menu payload with titled action menu section
function menu_assembly.build_with_action_menu(action_menu_spec, positioned_anchor_node_info, jump_spec)
  local menu_title = action_menu_spec.title or column_titles.hydra_default()

  return {
    title = menu_title,
    sections = section_order.with_action_menu(build_titled_action_menu_spec(action_menu_spec), jump_spec),
    anchor_node_info = positioned_anchor_node_info,
  }
end

return menu_assembly
