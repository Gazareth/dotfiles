local action_section = require("configs.hydra.atlantis.menu.sections.action")

local M = {}

--- Section ordering / variant from anchor context — not the Hydra hint spec (see menu.create_hint_menu).
function M.from_context(anchor_ctx)
  local jump_spec = anchor_ctx and anchor_ctx.jump_spec or nil
  if not anchor_ctx or not anchor_ctx.cursor_node_info then
    return { variant = "no_cursor", jump_spec = jump_spec }
  end

  local positioned_anchor_node_info = anchor_ctx.positioned_anchor_node_info

  local action_menu_spec = action_section(anchor_ctx)
  if type(action_menu_spec) ~= "table" then
    return {
      variant = "invalid_action_menu",
      positioned_anchor_node_info = positioned_anchor_node_info,
      jump_spec = jump_spec,
    }
  end

  if action_menu_spec.__abort_open == true then
    return {
      variant = "abort_action_menu",
      action_menu_spec = action_menu_spec,
      positioned_anchor_node_info = positioned_anchor_node_info,
      jump_spec = jump_spec,
    }
  end

  return {
    variant = "full",
    action_menu_spec = action_menu_spec,
    positioned_anchor_node_info = positioned_anchor_node_info,
    jump_spec = jump_spec,
  }
end

return M
