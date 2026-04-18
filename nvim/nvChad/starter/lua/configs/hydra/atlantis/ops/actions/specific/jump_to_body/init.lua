local body_lib = require("configs.hydra.atlantis.anchor.probe.node_kinds.function.lib.body")
local build_node_info = require("configs.hydra.atlantis.anchor.probe.treesitter.node_info").build_node_info
local common_actions = require("configs.hydra.atlantis.ops.lib.actions")

local M = {}

function M.build(ctx)
  local node_info = type(ctx) == "table" and ctx.node_info or nil
  local fn_node = node_info and node_info.node or nil
  if not fn_node then
    return common_actions.placeholder("Jump to", "body")
  end

  local n, body_node = body_lib.body_named_child_count(fn_node)
  if n <= 0 or not body_node then
    return common_actions.placeholder("Jump to", "body")
  end

  if n == 1 then
    local only = body_node:named_child(0)
    if not only then
      return common_actions.placeholder("Jump to", "body")
    end
    local child_info = build_node_info({ bufnr = node_info.bufnr, node = only })
    if not child_info then
      return common_actions.placeholder("Jump to", "body")
    end
    return function()
      common_actions.jump_to_target(common_actions.target_from_node_info(child_info))()
    end
  end

  local row, col = body_node:start()
  return function()
    pcall(vim.api.nvim_win_set_cursor, 0, { row + 1, col })
    pcall(vim.cmd, "normal! zz")
  end
end

return M
