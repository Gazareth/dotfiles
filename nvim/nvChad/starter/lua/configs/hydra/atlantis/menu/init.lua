local renderer = require("configs.hydra.atlantis.menu.renderer")
local title    = require("configs.hydra.atlantis.menu.components.title")
local layout   = require("configs.hydra.atlantis.menu.layout")
local sections = require("configs.hydra.atlantis.menu.sections")

local M = {}

M.title    = title
M.layout   = layout
M.sections = sections

-- Render node menu spec from pre-built runtime context
function M.get_node_menu_spec(runtime_ctx)
  return renderer.build_from_context(runtime_ctx)
end

-- Atlantis menu layout entrypoint
function M.get_layout_menu_spec(opts)
  return layout.build_menu_spec(opts)
end

return M
