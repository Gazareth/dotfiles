
-- Global command to set current directory to the nvim config dir
vim.api.nvim_create_user_command("CdHome", function()
  -- local Switcher = require("projections.switcher")
  -- Switcher:set_current()
  vim.cmd("cd "..vim.fn.stdpath('config'))
end, {})

-- GENERAL AUTOCMDS
-- Set cd to neovim config on start (if alpha is the only open buffer)
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function()
    local current_type = vim.bo.filetype
    if current_type == "alpha" or #current_type == 0 then
      vim.schedule(function() vim.cmd("CdHome") end)
    end
  end,
})

local bufCloseCandidates = {}

local isBufCloseCandidate = function(bi)
  if not vim.api.nvim_buf_is_valid(bi) then return 0 end
  local bn = vim.api.nvim_buf_get_name(bi)
  local line_count = vim.api.nvim_buf_line_count(bi)
  local bt = vim.bo[bi].filetype

  if (#bt == 0 and line_count == 1) or (#bn == 0 and bt == "alpha") then
    -- Candidate for closing.
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
  for _,bi in ipairs(bufCloseCandidates) do
    local c_score = isBufCloseCandidate(bi)
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

local setupCloseBufCandidates = function()
  -- Get valid buffers
  local valid_bufs = vim.tbl_filter(function(bi)
    return vim.api.nvim_buf_is_valid(bi)
      and vim.api.nvim_buf_get_option(bi, 'buflisted')
  end, vim.api.nvim_list_bufs())

  local candidates = {}
  for _, bi in ipairs(valid_bufs) do
    if isBufCloseCandidate(bi) > 0 then
      table.insert(candidates, bi)
    else
    end
  end
  if #candidates > 0 then
    bufCloseCandidates = candidates
    vim.defer_fn(buf_clean, 2000)
  end
end

-- Close empty buffers when left
vim.api.nvim_create_autocmd({ "BufLeave" }, {
  callback = setupCloseBufCandidates
})

-- Highlight yanked text for a brief period after yanking
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
  callback = function()
    vim.highlight.on_yank { higroup = "YankHighlight", timeout = 375 }
  end,
})

local open_config_files = function(left_rel_path, right_rel_path)
  local cfg_root = vim.fn.stdpath('config')
  local left_full_path = vim.fn.expand(cfg_root .. "/" .. left_rel_path)
  local right_full_path = vim.fn.expand(cfg_root .. "/" .. right_rel_path)
  local open_fn = "tabnew"
  if vim.bo.filetype == "alpha" then
    open_fn = "e"
  end

  vim.cmd(open_fn.." "..left_full_path.." | vsp "..right_full_path)
end

local config_commands = {
  ["EditCustomDashboard"] = {
    "lua/plugins/configs/alpha.lua", "lua/custom/plugins/overrides/alpha.lua"
  },
  ["EditKeyMappings"] = {
    "lua/core/mappings.lua", "lua/custom/mappings.lua"
  },
  ["EditInstalledPlugins"] = {
    "lua/plugins/init.lua", "lua/custom/plugins.lua"
  },
  ["EditCustomOptions"] = {
    "lua/core/options.lua", "lua/custom/options.lua"
  },
}

-- Create commands for each entry in `config_commands` above
for k,v in pairs(config_commands) do
  vim.api.nvim_create_user_command(k, function()
    open_config_files(v[1], v[2])
  end, {})
end

