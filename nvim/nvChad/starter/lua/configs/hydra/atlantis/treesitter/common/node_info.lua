local M = {}

-- Cursor row and column
local function get_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  return { row = row, col = col }
end

-- Node text with empty fallback
local function get_node_text(node, bufnr)
  local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
  if ok then
    return text
  end

  return ""
end

-- Node details shared by all parsers
function M.build_node_info(opts)
  opts = opts or {}

  local bufnr = opts.bufnr or 0
  local node = opts.node or vim.treesitter.get_node()
  if not node then
    return nil
  end

  local parent = node:parent()
  local grandparent = parent and parent:parent() or nil
  local start_row, start_col = node:start()
  local end_row, end_col = node:end_()

  return {
    bufnr = bufnr,
    cursor = get_cursor(),
    node = node,
    node_type = node:type(),
    text = get_node_text(node, bufnr),
    parent = parent,
    parent_type = parent and parent:type() or nil,
    grandparent = grandparent,
    grandparent_type = grandparent and grandparent:type() or nil,
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }
end

return M
