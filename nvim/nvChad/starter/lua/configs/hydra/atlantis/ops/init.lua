local M = {}

M.common = require("configs.hydra.atlantis.ops.common")
M.dispatch = require("configs.hydra.atlantis.ops.dispatch")
M.functions = require("configs.hydra.atlantis.ops.functions")
M.assignment = {
	rename = require("configs.hydra.atlantis.ops.assignment.rename"),
	jump = {
		lhs = require("configs.hydra.atlantis.ops.assignment.jump.lhs"),
		rhs = require("configs.hydra.atlantis.ops.assignment.jump.rhs"),
	},
}
M.assignments = M.assignment
M["function"] = {
	rename = require("configs.hydra.atlantis.ops.function.rename"),
	jump = {
		parameters = require("configs.hydra.atlantis.ops.function.jump.parameters"),
		body = require("configs.hydra.atlantis.ops.function.jump.body"),
		["return"] = require("configs.hydra.atlantis.ops.function.jump.return"),
		comment = require("configs.hydra.atlantis.ops.function.jump.comment"),
	},
}
M.identifier = {
	rename = require("configs.hydra.atlantis.ops.identifier.rename"),
}
M.filter = require("configs.hydra.atlantis.ops.filter")
M.change = require("configs.hydra.atlantis.ops.change")
M.select = require("configs.hydra.atlantis.ops.select")
M.edit = require("configs.hydra.atlantis.ops.edit")
M.swap = require("configs.hydra.atlantis.ops.swap")
M.remove = require("configs.hydra.atlantis.ops.remove")
M.navigate = require("configs.hydra.atlantis.ops.navigate")

return M
