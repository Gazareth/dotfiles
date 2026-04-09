local nodes = require("configs.hydra.atlantis.menu.nodes")
local title = require("configs.hydra.atlantis.menu.title")
local layout = require("configs.hydra.atlantis.menu.layout")
local columns = require("configs.hydra.atlantis.menu.columns")

local M = {}

M.title = title
M.layout = layout
M.columns = columns

-- Node menu entrypoint
function M.get_node_menu_spec(runtime_ctx)
  return nodes.get_node_menu_spec(runtime_ctx)
end

-- Atlantis menu layout entrypoint
function M.get_layout_menu_spec(opts)
  return layout.build_menu_spec(opts)
end

return M
