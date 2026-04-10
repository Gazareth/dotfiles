-- Aggregate action helper modules behind a stable ops.lib.actions import path
local node = require("configs.hydra.atlantis.ops.lib.actions.node")
local target = require("configs.hydra.atlantis.ops.lib.actions.target")
local visual = require("configs.hydra.atlantis.ops.lib.actions.visual")

local M = {}

-- Node label and placeholder helpers
M.resolve_node_label = node.resolve_node_label
M.placeholder = node.placeholder

-- Target derivation and jump helpers
M.target_from_node_info = target.target_from_node_info
M.resolve_target = target.resolve_target
M.jump_to_target = target.jump_to_target

-- Range and visual operator helpers
M.range_from_node_info = visual.range_from_node_info
M.resolve_range = visual.resolve_range
M.select_range = visual.select_range
M.visual_operator = visual.visual_operator

return M
