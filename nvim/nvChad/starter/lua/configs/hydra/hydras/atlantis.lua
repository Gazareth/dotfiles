local hydra_spec = require("configs.hydra.lib.hydra_spec")
local layout = require("configs.hydra.atlantis.menu.layout")

local M = {}

function M.open(menu_opts, hydra_opts)
  menu_opts = type(menu_opts) == "table" and menu_opts or {}
  hydra_spec.open(layout.build_menu_spec(menu_opts), hydra_opts)
end

return M
