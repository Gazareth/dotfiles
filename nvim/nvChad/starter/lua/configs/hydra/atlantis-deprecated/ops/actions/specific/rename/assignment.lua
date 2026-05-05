-- Build assignment rename from left-hand target
local lib = require("configs.hydra.atlantis-deprecated.ops.lib.actions")

local M = {}

-- Resolve assignment left-hand target from parsed payload
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

-- Trigger LSP rename at current cursor
local function run_rename()
  local ok, err = pcall(vim.lsp.buf.rename)
  if ok then
    return
  end

  vim.notify("Rename is unavailable: " .. tostring(err), vim.log.levels.WARN)
end

function M.build(ctx)
  local target = resolve_lhs_target(ctx)
  if not target then
    return lib.placeholder("Rename", "left hand side")
  end

  return function()
    run_rename()
  end
end

return M
