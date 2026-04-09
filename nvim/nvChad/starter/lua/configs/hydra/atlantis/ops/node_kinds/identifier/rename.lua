local common_actions = require("configs.hydra.atlantis.ops.node_kinds.common")

local M = {}

-- LSP rename runner
local function run_rename()
  local ok, err = pcall(vim.lsp.buf.rename)
  if ok then
    return
  end

  vim.notify("Rename is unavailable: " .. tostring(err), vim.log.levels.WARN)
end

-- Rename at identifier target
function M.build(ctx)
  local target = common_actions.resolve_target(ctx)
  if not target then
    return common_actions.placeholder("Rename", common_actions.resolve_node_label(ctx))
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
