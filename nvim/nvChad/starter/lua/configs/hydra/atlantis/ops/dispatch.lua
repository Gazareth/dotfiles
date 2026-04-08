local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes

local M = {}

-- Action module map
local action_modules = {
  rename = {
    [supported_nodes.assignment] = "configs.hydra.atlantis.ops.assignment.rename",
    [supported_nodes.fn] = "configs.hydra.atlantis.ops.function.rename",
    [supported_nodes.identifier] = "configs.hydra.atlantis.ops.identifier.rename",
  },
  jump_to_lhs = {
    [supported_nodes.assignment] = "configs.hydra.atlantis.ops.assignment.jump.lhs",
  },
  jump_to_rhs = {
    [supported_nodes.assignment] = "configs.hydra.atlantis.ops.assignment.jump.rhs",
  },
}

-- Fallback module map
local fallback_modules = {
  rename = "configs.hydra.atlantis.ops.common",
}

-- Safe module loader
local function load_module(module_path)
  if type(module_path) ~= "string" or module_path == "" then
    return nil
  end

  local ok, mod = pcall(require, module_path)
  if not ok then
    return nil
  end

  return mod
end

-- Action builder resolver
function M.resolve(action_name, node_kind)
  local by_node = action_modules[action_name]
  local module_path = type(by_node) == "table" and by_node[node_kind] or nil
  local mod = load_module(module_path)
  if type(mod) == "table" and type(mod.build) == "function" then
    return mod.build
  end

  local fallback = load_module(fallback_modules[action_name])
  if type(fallback) == "table" and type(fallback.placeholder) == "function" then
    return function(ctx)
      return fallback.placeholder("Rename", fallback.resolve_node_label(ctx))
    end
  end

  return nil
end

-- Build action closure
function M.build(action_name, node_kind, ctx)
  local builder = M.resolve(action_name, node_kind)
  if type(builder) ~= "function" then
    return nil
  end

  return builder(ctx or {}, node_kind)
end

-- Builder wrapper for registry tables
function M.builder(action_name)
  return function(ctx, node_kind)
    return M.build(action_name, node_kind, ctx)
  end
end

return M
