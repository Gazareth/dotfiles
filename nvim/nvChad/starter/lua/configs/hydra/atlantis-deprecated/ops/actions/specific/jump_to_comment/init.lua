local M = {}

-- Returns a function that jumps to the first comment line preceding the anchor node,
-- or nil if no consecutive comment block immediately precedes it (omits the menu row).
--
-- Uses a line-based scan rather than the treesitter child list because in Lua
-- treesitter, comments can be attached to different parent nodes depending on
-- their position (e.g. inside a function_declaration vs inside a block).
function M.build(ctx)
  local node_info = type(ctx) == "table" and ctx.node_info or nil
  local node = node_info and node_info.node
  if not node then return nil end

  local bufnr = node_info.bufnr or vim.api.nvim_get_current_buf()
  local start_row = node:start()  -- 0-indexed

  -- Scan lines immediately above the anchor for consecutive `--` comments.
  local first_comment_row = nil
  local r = start_row - 1
  while r >= 0 do
    local line = (vim.api.nvim_buf_get_lines(bufnr, r, r + 1, false) or {})[1]
    if line and line:match("^%s*%-%-") then
      first_comment_row = r
      r = r - 1
    else
      break
    end
  end

  if not first_comment_row then return nil end

  return function()
    pcall(vim.api.nvim_win_set_cursor, 0, { first_comment_row + 1, 0 })
  end
end

return M
