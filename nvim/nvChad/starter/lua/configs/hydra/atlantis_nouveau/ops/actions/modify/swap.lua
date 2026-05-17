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

function M.with_prev(result)
  local nav = result.navigation
  if not nav or not nav.prev_sibling then return end
  local target = nav.prev_sibling.range
  swap(result.bufnr, result.range, target)
  reopen(result.bufnr, target.start_row, target.start_col)
end

function M.with_next(result)
  local nav = result.navigation
  if not nav or not nav.next_sibling then return end
  local target = nav.next_sibling.range
  swap(result.bufnr, result.range, target)
  reopen(result.bufnr, target.start_row, target.start_col)
end

return M
