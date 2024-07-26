-- To find any highlight groups: "<cmd> Telescope highlights"
-- Each highlight group can take a table with variables fg, bg, bold, italic, etc
-- base30 variable names can also be used as colors

local M = {}

M.override = {
  CursorLine = {
    bg = "black2",
  },
  Comment = {
    italic = true,
  },

  St_NormalMode = {
    bg = "white",
  },
  St_InsertMode = {
    bg = "yellow",
  },
  St_TerminalMode = {
    bg = "blue",
  },
  St_NTerminalMode = {
    bg = "blue",
  },
  St_VisualMode = {
    bg = "dark_purple",
  },
  St_ReplaceMode = {
    bg = "orange",
  },
  St_ConfirmMode = {
    bg = "teal",
  },
  St_CommandMode = {
    bg = "red",
  },
  St_SelectMode = {
    bg = "dark_purple",
  },

  St_NormalModeSep = {
    fg = "white",
  },

  St_InsertModeSep = {
    fg = "yellow",
  },

  St_TerminalModeSep = {
    fg = "blue",
  },

  St_NTerminalModeSep = {
    fg = "blue",
  },

  St_VisualModeSep = {
    fg = "dark_purple",
  },

  St_ReplaceModeSep = {
    fg = "orange",
  },

  St_ConfirmModeSep = {
    fg = "teal",
  },

  St_CommandModeSep = {
    fg = "red",
  },

  St_SelectModeSep = {
    fg = "dark_purple",
  },

  St_EmptySpace = {
  },

  St_file_sep = {
    fg = "lightbg",
    bg = "one_bg",
  }
}

local searchHighlight = function(isCurrent)
  local fg_col = "black"
  local bg_col = "purple"
  local isBold  = false
  if isCurrent then
    -- fg_col = "#ffffff"
    bg_col = "dark_purple"
    isBold = true
  end
  return { fg = fg_col, bg = bg_col, bold = isBold }
end

M.add = {
  -- NvimTreeOpenedFolderName = { fg = "blue", bold = true },
  -- NvimTreeOpenedFile = { fg = "teal", bold = true, italic = true },
  St_file_modified = {
    bg = "lightbg",
    fg = "white",
    bold = true,
  },
  St_file_folder_info = {
    fg = "white",
    bg = "one_bg",
  },
  St_folder_sep = {
    fg = "one_bg",
    bg = "statusline_bg",
  },
  St_folder_head = {
    fg = "lighter_grey",
    bg = "one_bg",
  },
  St_folder_chevs = {
    fg = "light_grey",
    bg = "one_bg",
    bold = true,
  },
  St_file_git_sep = {
    fg = "black2",
    bg = "statusline_bg",
  },
  St_LspAttachedName = {
    fg = "dark_purple",
    bold = true,
  },
  St_cwd_project = {
    fg = "lighter_grey",
    bg = "lightbg",
    -- bold = true
    -- italic = true
  },
  CurSearch = searchHighlight(true),
  IncSearch = searchHighlight(true),
  Search = searchHighlight(false),
  Substitute = { fg = "black", bg = "sun", bold = true },
  YankHighlight = { fg = "#dddddd", bg = "one_bg3" },
  VisualMultiCursor = { fg = "grey_fg2", bg = "dark_purple" },
  InsertModeCursor = { fg = "black", bg = "sun" },
  VisualModeCursor = { fg = "black", bg = "dark_purple" },
  IndentBlanklineIndent1 = { fg  = "#E06C75" },
  IndentBlanklineIndent2 = { fg  = "#E5C07B" },
  IndentBlanklineIndent3 = { fg  = "#98C379" },
  IndentBlanklineIndent4 = { fg  = "#56B6C2" },
  IndentBlanklineIndent5 = { fg  = "#61AFEF" },
  IndentBlanklineIndent6 = { fg  = "#C678DD" },
}

return M
