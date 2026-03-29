local M = {}

function M.setup()
	local menus = require("configs.nui.menus")

	menus.namu_all:bind("n", "<leader>nn", "Namu Symbols Menu")
	menus.treewalker_all:bind("n", "<leader>tt", "Treewalker Scope & Actions")
end

return M
