local anchor = require("configs.hydra.atlantis.schema.actions.anchor")
local menu = require("configs.hydra.atlantis.schema.actions.menu")
local layout = require("configs.hydra.atlantis.schema.actions.layout")

return vim.tbl_extend("force", {}, anchor, menu, layout)
