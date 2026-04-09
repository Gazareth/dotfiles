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

-- Node range from node info
function M.range_from_node_info(node_info)
  if type(node_info) ~= "table" then
    return nil
  end

  local start_row = node_info.start_row
  local start_col = node_info.start_col
  local end_row = node_info.end_row
  local end_col = node_info.end_col

  if type(start_row) ~= "number" or type(start_col) ~= "number" then
    return nil
  end

  if type(end_row) ~= "number" or type(end_col) ~= "number" then
    return nil
  end

  if end_row < start_row or (end_row == start_row and end_col <= start_col) then
    return nil
  end

  return {
    bufnr = node_info.bufnr,
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }
end

-- Inclusive visual end position
local function inclusive_visual_end(bufnr, end_row, end_col)
  if end_col > 0 then
    return end_row, end_col - 1
  end

  if end_row <= 0 then
    return 0, 0
  end

  local prev_row = end_row - 1
  local line = vim.api.nvim_buf_get_lines(bufnr, prev_row, prev_row + 1, false)[1] or ""
  local last_col = #line > 0 and (#line - 1) or 0
  return prev_row, last_col
end

-- Resolve explicit range or node range
function M.resolve_range(ctx)
  if type(ctx) ~= "table" then
    return nil
  end

  if type(ctx.range) == "table" then
    return ctx.range
  end

  return M.range_from_node_info(ctx.node_info)
end

-- Visual select a range
function M.select_range(range)
  if type(range) ~= "table" then
    return false
  end

  local bufnr = range.bufnr
  if type(bufnr) ~= "number" or not vim.api.nvim_buf_is_valid(bufnr) then
    bufnr = vim.api.nvim_get_current_buf()
  end

  if type(range.bufnr) == "number" and vim.api.nvim_buf_is_valid(range.bufnr) then
    vim.api.nvim_set_current_buf(range.bufnr)
  end

  local start_row = (range.start_row or 0) + 1
  local start_col = range.start_col or 0
  local end_row, end_col = inclusive_visual_end(bufnr, range.end_row or 0, range.end_col or 0)

  local ok_start = pcall(vim.api.nvim_win_set_cursor, 0, { start_row, start_col })
  if not ok_start then
    return false
  end

  pcall(vim.cmd, "normal! v")
  local ok_end = pcall(vim.api.nvim_win_set_cursor, 0, { end_row + 1, end_col })
  return ok_end
end

-- Visual operator action builder
function M.visual_operator(op_name, op_key, ctx)
  return function()
    local range = M.resolve_range(ctx)
    if not range or not M.select_range(range) then
      vim.notify(op_name .. " " .. M.resolve_node_label(ctx) .. " is not available.", vim.log.levels.INFO)
      return
    end

    pcall(vim.cmd, "normal! " .. op_key)
  end
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

return M
