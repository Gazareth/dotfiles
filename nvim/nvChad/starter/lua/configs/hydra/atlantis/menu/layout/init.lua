local runtime_context = require("configs.hydra.atlantis.runtime.context")
local section_assembly = require("configs.hydra.atlantis.menu.layout.assembly")
local modify_section = require("configs.hydra.atlantis.menu.sections.modify")

local M = {}

-- Atlantis menu structure
function M.build_menu_spec(opts)
  local ctx = runtime_context.build(opts)
  if not ctx.cursor_node_info then
    return section_assembly.build_without_cursor()
  end

  local positioned_anchor_node_info = ctx.positioned_anchor_node_info

  local modify_spec = modify_section(ctx)
  if type(modify_spec) ~= "table" then
    return section_assembly.build_with_invalid_modify(positioned_anchor_node_info)
  end

  if modify_spec.__abort_open == true then
    return section_assembly.build_with_abort_modify(modify_spec, positioned_anchor_node_info)
  end

  return section_assembly.build_with_modify(modify_spec, positioned_anchor_node_info)
end

return M