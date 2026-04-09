local M = {}
local parameter_sibling = require("configs.hydra.atlantis.ops.node_kinds.function.parameter.sibling")

M.common = require("configs.hydra.atlantis.ops.node_kinds.common")
M.resolver = require("configs.hydra.atlantis.ops.resolver")
M.assignment = {
	rename = require("configs.hydra.atlantis.ops.node_kinds.assignment.rename"),
	jump = {
		lhs = require("configs.hydra.atlantis.ops.node_kinds.assignment.jump.lhs"),
		rhs = require("configs.hydra.atlantis.ops.node_kinds.assignment.jump.rhs"),
	},
}
M["function"] = {
	rename = require("configs.hydra.atlantis.ops.node_kinds.function.rename"),
	call_hierarchy = require("configs.hydra.atlantis.ops.node_kinds.function.call_hierarchy"),
	parameter = {
		sibling = parameter_sibling,
	},
	jump = {
		parameters = require("configs.hydra.atlantis.ops.node_kinds.function.jump.parameters"),
		body = require("configs.hydra.atlantis.ops.node_kinds.function.jump.body"),
		["return"] = require("configs.hydra.atlantis.ops.node_kinds.function.jump.return"),
		comment = require("configs.hydra.atlantis.ops.node_kinds.function.jump.comment"),
	},
}
M.identifier = {
	rename = require("configs.hydra.atlantis.ops.node_kinds.identifier.rename"),
}
return M
