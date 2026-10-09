local path_utils = require("functions.path")

local M = {}

function M.get_display_name(tab)
  local editor_bufname = ""

  -- Find the non-Fyler editor window in the tab
  for _, w in ipairs(tab.wins().wins) do
    local b = w.buf()
    local b_id = b and b.id
    if b_id and vim.bo[b_id].filetype ~= "fyler_finder" and vim.bo[b_id].buftype ~= "nofile" then
      local name = vim.api.nvim_buf_get_name(b_id)
      if name ~= "" then
        editor_bufname = name
        break
      end
    end
  end

  local cwd = vim.fs.normalize(vim.fn.getcwd())
  local collapsed_cwd = path_utils.collapse_home(cwd)
  local cwd_name = (collapsed_cwd == "~") and "~" or (vim.fs.basename(cwd) or cwd)

  if editor_bufname ~= "" then
    local display = path_utils.format_display(path_utils.get_relative_path(editor_bufname))
    return string.format("[Fyler] %s (%s)", display, cwd_name)
  else
    return string.format("[Fyler] (%s)", cwd_name)
  end
end

return M
