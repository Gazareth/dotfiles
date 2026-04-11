local modify_section = require("configs.hydra.atlantis.menu.sections.modify")

local M = {}

--- Section ordering / variant from anchor context — not the Hydra hint spec (see menu.create_hint_menu).
function M.from_context(anchor_ctx)
  local jump_spec = anchor_ctx and anchor_ctx.jump_spec or nil
  if not anchor_ctx or not anchor_ctx.cursor_node_info then
    return { variant = "no_cursor", jump_spec = jump_spec }
  end

  local positioned_anchor_node_info = anchor_ctx.positioned_anchor_node_info

  local modify_spec = modify_section(anchor_ctx)
  if type(modify_spec) ~= "table" then
    return {
      variant = "invalid_modify",
      positioned_anchor_node_info = positioned_anchor_node_info,
      jump_spec = jump_spec,
    }
  end

  if modify_spec.__abort_open == true then
    return {
      variant = "abort_modify",
      modify_spec = modify_spec,
      positioned_anchor_node_info = positioned_anchor_node_info,
      jump_spec = jump_spec,
    }
  end

  return {
    variant = "full",
    modify_spec = modify_spec,
    positioned_anchor_node_info = positioned_anchor_node_info,
    jump_spec = jump_spec,
  }
end

return M
