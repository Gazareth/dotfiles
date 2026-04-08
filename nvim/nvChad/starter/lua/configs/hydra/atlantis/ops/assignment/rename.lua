local common_actions = require("configs.hydra.atlantis.ops.common")

local M = {}

-- Assignment lhs target
local function resolve_lhs_target(ctx)
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

-- LSP rename runner
local function run_rename()
  local ok, err = pcall(vim.lsp.buf.rename)
  if ok then
    return
  end

  vim.notify("Rename is unavailable: " .. tostring(err), vim.log.levels.WARN)
end

-- Rename at lhs target
function M.build(ctx)
  local target = resolve_lhs_target(ctx)
  if not target then
    return common_actions.placeholder("Rename", "left hand side")
  end

  return function()
    local jump = common_actions.jump_to_target(target)
    if type(jump) == "function" then
      jump()
    end

    run_rename()
  end
end

return M
