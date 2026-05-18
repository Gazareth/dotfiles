local M = {}

local function get_text(bufnr, r)
  return vim.api.nvim_buf_get_text(bufnr, r.start_row, r.start_col, r.end_row, r.end_col, {})
end

local function set_text(bufnr, r, lines)
  vim.api.nvim_buf_set_text(bufnr, r.start_row, r.start_col, r.end_row, r.end_col, lines)
end

local function ranges_overlap(a, b)
  local a_before_b = a.end_row < b.start_row or (a.end_row == b.start_row and a.end_col <= b.start_col)
  local b_before_a = b.end_row < a.start_row or (b.end_row == a.start_row and b.end_col <= a.start_col)
  return not (a_before_b or b_before_a)
end

local function swap(bufnr, ra, rb)
  if ranges_overlap(ra, rb) then return end
  local first, second
  if ra.start_row < rb.start_row or (ra.start_row == rb.start_row and ra.start_col < rb.start_col) then
    first, second = ra, rb
  else
    first, second = rb, ra
  end
  local text_first  = get_text(bufnr, first)
  local text_second = get_text(bufnr, second)
  set_text(bufnr, second, text_first)
  set_text(bufnr, first,  text_second)
end

local function reopen(bufnr, row, col)
  vim.api.nvim_win_set_cursor(0, { row + 1, col })
  vim.schedule(function()
    require("configs.hydra.atlantis_nouveau").open({ bufnr = bufnr })
  end)
end

-- Returns the effective range for a node, extended to include its comment block.
-- Statement focus: comment_range present → extend backward to include preceding comments.
-- Comment focus: associated_statement present → extend forward to include the statement.
local function effective_range(node)
  if node.comment_range then
    return {
      start_row = node.comment_range.start_row,
      start_col = node.comment_range.start_col,
      end_row   = node.range.end_row,
      end_col   = node.range.end_col,
    }
  elseif node.associated_statement then
    local st = node.associated_statement
    return {
      start_row = node.range.start_row,
      start_col = node.range.start_col,
      end_row   = st.range.end_row,
      end_col   = st.range.end_col,
    }
  end
  return node.range
end

function M.with_prev(result)
  local nav = result.navigation
  if not nav or not nav.prev_sibling then return end
  local my_eff  = effective_range(result)
  local tgt_eff = effective_range(nav.prev_sibling)
  swap(result.bufnr, my_eff, tgt_eff)
  -- Land on the focused node's statement row (not its comment) in its new position.
  local my_offset = result.range.start_row - my_eff.start_row
  reopen(result.bufnr, tgt_eff.start_row + my_offset, result.range.start_col)
end

function M.with_next(result)
  local nav = result.navigation
  if not nav or not nav.next_sibling then return end
  local my_eff  = effective_range(result)
  local tgt_eff = effective_range(nav.next_sibling)
  swap(result.bufnr, my_eff, tgt_eff)
  -- tgt_eff.start_row + delta = top of the current node's new position;
  -- + my_offset shifts past any comment lines to land on the statement row.
  local delta     = (tgt_eff.end_row - tgt_eff.start_row) - (my_eff.end_row - my_eff.start_row)
  local my_offset = result.range.start_row - my_eff.start_row
  reopen(result.bufnr, tgt_eff.start_row + delta + my_offset, result.range.start_col)
end

return M
