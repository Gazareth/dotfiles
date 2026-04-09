local M = {}

local lib = require("configs.hydra.atlantis.ops.node_kinds.common.lib")
local inspect = require("configs.hydra.atlantis.ops.node_kinds.common.inspect")
local change = require("configs.hydra.atlantis.ops.node_kinds.common.change")
local select = require("configs.hydra.atlantis.ops.node_kinds.common.select")
local yank = require("configs.hydra.atlantis.ops.node_kinds.common.yank")
local delete = require("configs.hydra.atlantis.ops.node_kinds.common.delete")
local swap = require("configs.hydra.atlantis.ops.node_kinds.common.swap")

-- Helper exports for node actions
M.resolve_node_label = lib.resolve_node_label
M.target_from_node_info = lib.target_from_node_info
M.resolve_target = lib.resolve_target
M.jump_to_target = lib.jump_to_target
M.placeholder = lib.placeholder

-- Action exports for node actions
M.inspect = inspect.build
M.change = change.build
M.select = select.build
M.yank = yank.build
M.delete = delete.build
M.swap = swap.build

return M
