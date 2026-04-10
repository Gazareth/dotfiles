-- Assemble final menu payload from context and modify section result
local section_order = require("configs.hydra.atlantis.menu.layout.sections")

local M = {}

-- Return a modify section copy with a consistent title label
local function build_titled_modify_spec(modify_spec)
  return vim.tbl_extend("force", {}, modify_spec, {
    title = " ✦ Modify",
  })
end

-- Build menu payload for empty cursor state
function M.build_without_cursor(jump_spec)
  return {
    title = "Treewalker",
    sections = section_order.build_default(jump_spec),
  }
end

-- Build menu payload when modify section failed to produce a table
function M.build_with_invalid_modify(positioned_anchor_node_info, jump_spec)
  return {
    title = "Treewalker",
    sections = section_order.build_default(jump_spec),
    anchor_node_info = positioned_anchor_node_info,
  }
end

-- Build menu payload when modify section requests abort-open behavior
function M.build_with_abort_modify(modify_spec, positioned_anchor_node_info, jump_spec)
  return {
    title = "Treewalker",
    sections = section_order.with_modify(modify_spec, jump_spec),
    anchor_node_info = positioned_anchor_node_info,
  }
end

-- Build normal menu payload with titled modify section
function M.build_with_modify(modify_spec, positioned_anchor_node_info, jump_spec)
  local menu_title = modify_spec.title or "Treewalker"

  return {
    title = menu_title,
    sections = section_order.with_modify(build_titled_modify_spec(modify_spec), jump_spec),
    anchor_node_info = positioned_anchor_node_info,
  }
end

return M
