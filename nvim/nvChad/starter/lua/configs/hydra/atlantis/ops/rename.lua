local common_actions = require("configs.hydra.atlantis.ops.common")
local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes

local M = {}

-- Safe LSP rename runner
local function run_lsp_rename()
  local ok, err = pcall(vim.lsp.buf.rename)
  if ok then
    return
  end

  vim.notify("Rename is unavailable: " .. tostring(err), vim.log.levels.WARN)
end

-- Rename at target cursor
local function rename_at_target(target)
  return function()
    local jump = common_actions.jump_to_target(target)
    if type(jump) == "function" then
      jump()
    end

    run_lsp_rename()
  end
end

-- Assignment left side target
local function resolve_assignment_lhs_target(ctx)
  if type(ctx) == "table" and type(ctx.target) == "table" then
    return ctx.target
  end

  local parsed = type(ctx) == "table" and ctx.parsed or nil
  local targets = type(parsed) == "table" and parsed.targets or nil
  if type(targets) == "table" and type(targets.left) == "table" then
    return targets.left
  end

  return nil
end

-- Function name target
local function resolve_function_name_target(ctx)
  if type(ctx) == "table" and type(ctx.target) == "table" then
    return ctx.target
  end

  local parsed = type(ctx) == "table" and ctx.parsed or nil
  local targets = type(parsed) == "table" and parsed.targets or nil
  if type(targets) == "table" and type(targets.function_name) == "table" then
    return targets.function_name
  end

  return common_actions.resolve_target(ctx)
end

-- Rename action builder by node kind
function M.build(ctx, node_kind)
  if node_kind == supported_nodes.assignment then
    local lhs_target = resolve_assignment_lhs_target(ctx)
    if not lhs_target then
      return common_actions.placeholder("Rename", "left hand side")
    end

    return rename_at_target(lhs_target)
  end

  if node_kind == supported_nodes.fn then
    local function_name_target = resolve_function_name_target(ctx)
    if not function_name_target then
      return common_actions.placeholder("Rename", "function name")
    end

    return rename_at_target(function_name_target)
  end

  if node_kind == supported_nodes.identifier then
    local target = common_actions.resolve_target(ctx)
    if not target then
      return common_actions.placeholder("Rename", common_actions.resolve_node_label(ctx))
    end

    return rename_at_target(target)
  end

  return common_actions.placeholder("Rename", common_actions.resolve_node_label(ctx))
end

return M
