local anchor = require("configs.hydra.atlantis.schema.actions.anchor")
local menu = require("configs.hydra.atlantis.schema.actions.menu")

return vim.tbl_extend("force", {}, anchor, menu)
