-- Turn a resolved menu layout (from menu.layout) into a Hydra hint spec (title, sections, anchor).
local assembly = require("configs.hydra.atlantis.menu.layout.assembly")

local M = {}

function M.create_hint_menu(layout)
  if layout.variant == "no_cursor" then
    return assembly.build_without_cursor(layout.jump_spec)
  end
  if layout.variant == "invalid_action_menu" then
    return assembly.build_with_invalid_action_menu(layout.positioned_anchor_node_info, layout.jump_spec)
  end
  if layout.variant == "abort_action_menu" then
    return assembly.build_with_abort_action_menu(
      layout.action_menu_spec,
      layout.positioned_anchor_node_info,
      layout.jump_spec
    )
  end
  if layout.variant == "full" then
    return assembly.build_with_action_menu(
      layout.action_menu_spec,
      layout.positioned_anchor_node_info,
      layout.jump_spec
    )
  end
  error("create_hint_menu: unknown layout variant")
end

return M
