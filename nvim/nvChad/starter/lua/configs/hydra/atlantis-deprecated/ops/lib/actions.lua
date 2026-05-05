local node = require("configs.hydra.atlantis-deprecated.ops.lib.node")
local target = require("configs.hydra.atlantis-deprecated.ops.lib.target")
local visual = require("configs.hydra.atlantis-deprecated.ops.lib.visual")

local M = {}

M.resolve_node_label = node.resolve_node_label
M.placeholder = node.placeholder

M.target_from_node_info = target.target_from_node_info
M.resolve_target = target.resolve_target
M.jump_to_target = target.jump_to_target

M.range_from_node_info = visual.range_from_node_info
M.resolve_range = visual.resolve_range
M.select_range = visual.select_range
M.visual_operator = visual.visual_operator

return M
