local anchor = require("configs.hydra.atlantis-deprecated.schema.actions.anchor")
local menu = require("configs.hydra.atlantis-deprecated.schema.actions.menu")
local layout = require("configs.hydra.atlantis-deprecated.schema.actions.layout")

return vim.tbl_extend("force", {}, anchor, menu, layout)
