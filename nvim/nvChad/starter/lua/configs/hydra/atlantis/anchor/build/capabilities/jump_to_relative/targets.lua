local build_node_info = require("configs.hydra.atlantis.anchor.probe.treesitter.node_info").build_node_info

local M = {}

function M.resolve(selected_node_info, relation)
  if not selected_node_info or not selected_node_info.node then
    return nil
  end

  local node = selected_node_info.node
  local target = nil

  if relation == "parent" then
    target = node:parent()
    if not target then
      target = node:prev_named_sibling()
    end
  elseif relation == "prev_sibling" then
    target = node:prev_named_sibling()
  elseif relation == "next_sibling" then
    target = node:next_named_sibling()
  elseif relation == "child" then
    target = node:named_child(0)
  end

  if not target then
    return nil
  end

  return build_node_info({
    bufnr = selected_node_info.bufnr,
    node = target,
  })
end

function M.is_document_root(node_info)
  local node = node_info and node_info.node
  if not node then
    return false
  end
  return node:parent() == nil
end

function M.jump_action(target_node_info)
  return function()
    if not target_node_info then
      return
    end

    local row = (target_node_info.start_row or 0) + 1
    local col = target_node_info.start_col or 0
    pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
  end
end

return M
