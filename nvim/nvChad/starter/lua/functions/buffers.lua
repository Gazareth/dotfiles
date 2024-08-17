local M = {}

local buf_close_candidates = {}

-- Candidates for closure are buffers that are both empty & not being shown in any window
local is_close_buf_candidate = function(bi)
  if not vim.api.nvim_buf_is_valid(bi) then return 0 end
  local bn = vim.api.nvim_buf_get_name(bi)
  local line_count = vim.api.nvim_buf_line_count(bi)
  local bt = vim.bo[bi].filetype

  if (#bt == 0 and line_count == 1) or (#bn == 0 and bt == "alpha") then
    local bw = vim.fn.win_findbuf(bi)
    local bwe = vim.fn.empty(bw)
    if bwe == 1 then
      return 1
    elseif #bw == 1 then
      -- Buffer is not hidden... it is being shown on at least one window!
      -- But fear not! If these windows are the only ones in their tabs, we can close!
      for _,wid in ipairs(bw) do
        local tp = vim.api.nvim_win_get_tabpage(wid)
        local ws = vim.api.nvim_tabpage_list_wins(tp)
        if #ws == 1 then
          return 2
        end
      end
    end
  end
  return 0
end

local buf_clean = function()
  for _,bi in ipairs(buf_close_candidates) do
    local c_score = is_close_buf_candidate(bi)
    if c_score > 0 then
      if c_score == 1 then
        vim.cmd("bd "..bi)
      elseif c_score == 2 then
        local bw = vim.fn.win_findbuf(bi)
        if #bw == 1 then
          vim.api.nvim_win_close(bw[1], false)
        end
      end
    end
  end
end

M.close_empty_buffers = function()
  -- Get valid buffers
  local valid_bufs = vim.tbl_filter(function(bi)
    return vim.api.nvim_buf_is_valid(bi)
      and vim.api.nvim_get_option_value('buflisted', { buf = bi })
  end, vim.api.nvim_list_bufs())

  local candidates = {}
  for _, bi in ipairs(valid_bufs) do
    if is_close_buf_candidate(bi) > 0 then
      table.insert(candidates, bi)
    else
    end
  end
  if #candidates > 0 then
    buf_close_candidates = candidates
    vim.defer_fn(buf_clean, 2000)
  end
end

return M