local M = {}

-- Export action resolver and non-action operation groups
M.resolver = require("configs.hydra.atlantis.ops.resolver")

-- Export action modules by scope for direct inspection and testing
M.actions = {
	common = {
		change = require("configs.hydra.atlantis.ops.actions.common.change.init"),
		rename = require("configs.hydra.atlantis.ops.actions.common.rename.init"),
		select = require("configs.hydra.atlantis.ops.actions.common.select.init"),
		yank = require("configs.hydra.atlantis.ops.actions.common.yank.init"),
		delete = require("configs.hydra.atlantis.ops.actions.common.delete.init"),
		inspect = require("configs.hydra.atlantis.ops.actions.common.inspect.init"),
		view_call_hierarchy = require("configs.hydra.atlantis.ops.actions.common.view_call_hierarchy.init"),
	},
	specific = {
		rename = require("configs.hydra.atlantis.ops.actions.specific.rename.init"),
		jump_lhs = require("configs.hydra.atlantis.ops.actions.specific.jump_lhs.init"),
		jump_rhs = require("configs.hydra.atlantis.ops.actions.specific.jump_rhs.init"),
		jump_to_body = require("configs.hydra.atlantis.ops.actions.specific.jump_to_body.function"),
		jump_to_parameter = require("configs.hydra.atlantis.ops.actions.specific.jump_to_parameter.function"),
	},
}

-- Export non-action operations that remain node-kind oriented
M.parameter = {
	sibling = require("configs.hydra.atlantis.ops.actions.specific.parameter.sibling"),
}

return M
