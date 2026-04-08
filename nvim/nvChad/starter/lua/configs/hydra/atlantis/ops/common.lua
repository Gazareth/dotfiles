local M = {}

-- Node label from action context
function M.resolve_node_label(ctx)
  local parsed = type(ctx) == "table" and ctx.parsed or nil
  local node_info = type(ctx) == "table" and ctx.node_info or nil

  return (parsed and parsed.display_name)
    or (parsed and parsed.node_type)
    or (node_info and node_info.node_type)
    or "node"
end

-- Build jump target from node info
function M.target_from_node_info(node_info)
  if type(node_info) ~= "table" then
    return nil
  end

  local row = node_info.start_row
  local col = node_info.start_col
  if type(row) ~= "number" or type(col) ~= "number" then
    return nil
  end

  return {
    bufnr = node_info.bufnr,
    row = row,
    col = col,
  }
end

-- Resolve explicit target or node derived target
function M.resolve_target(ctx)
  if type(ctx) ~= "table" then
    return nil
  end

  if type(ctx.target) == "table" then
    return ctx.target
  end

  return M.target_from_node_info(ctx.node_info)
end

-- Jump to target with cursor placement and zz
function M.jump_to_target(target)
  return function()
    if type(target) ~= "table" then
      return
    end

    if type(target.bufnr) == "number" and vim.api.nvim_buf_is_valid(target.bufnr) then
      vim.api.nvim_set_current_buf(target.bufnr)
    end

    local row = (target.row or 0) + 1
    local col = target.col or 0
    pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
    pcall(vim.cmd, "normal! zz")
  end
end

-- Placeholder notify action
function M.placeholder(verb, label)
  return function()
    vim.notify(verb .. " " .. label .. " is not implemented yet.", vim.log.levels.INFO)
  end
end

-- Inspect action from context
function M.inspect(ctx)
  return function()
    local node_info = type(ctx) == "table" and ctx.node_info or nil
    local parsed = type(ctx) == "table" and ctx.parsed or nil
    local semantic = parsed and parsed.semantic or {}
    local node_label = M.resolve_node_label(ctx)

    local message = table.concat({
      "Atlantis node inspect [" .. node_label .. "]:",
      "node_type=" .. tostring((parsed and parsed.node_type) or (node_info and node_info.node_type)),
      "tier=" .. tostring(parsed and parsed.node_tier),
      "kind=" .. tostring(parsed and parsed.semantic_kind),
      "actionable=" .. tostring(parsed and parsed.actionable),
      "status=" .. tostring(semantic.status),
    }, " ")

    vim.notify(message, vim.log.levels.INFO)
  end
end

-- Change action from context
function M.change(ctx)
  return M.placeholder("Change", M.resolve_node_label(ctx))
end

-- Select action from context
function M.select(ctx)
  return M.placeholder("Select", M.resolve_node_label(ctx))
end

-- Yank action from context
function M.yank(ctx)
  return M.placeholder("Yank", M.resolve_node_label(ctx))
end

-- Delete action from context
function M.delete(ctx)
  return M.placeholder("Delete", M.resolve_node_label(ctx))
end

-- Swap action from context
function M.swap(ctx)
  return M.placeholder("Swap", M.resolve_node_label(ctx))
end

-- Jump action from context
function M.jump(ctx)
  local target = M.resolve_target(ctx)
  if not target then
    return M.placeholder("Jump to", M.resolve_node_label(ctx))
  end

  return M.jump_to_target(target)
end

return M
