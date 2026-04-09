local M = {}
local parameter_sibling = require("configs.hydra.atlantis.ops.function.parameter.sibling")

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
M["function"] = {
	rename = require("configs.hydra.atlantis.ops.function.rename"),
	parameter = {
		sibling = parameter_sibling,
	},
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

return M
