local M = {}

M.base_30 = {
  white          = "#fff8f9",
  darker_black   = "#211c1c",
  black          = "#2c2525", -- Background
  black2         = "#332b2b",
  one_bg         = "#403838",
  one_bg2        = "#4d4343",
  one_bg3        = "#5b5353",
  grey           = "#72696a", -- Darker grey for comments
  grey_fg        = "#948a8b",
  grey_fg2       = "#b5a9aa",
  light_grey     = "#c8bebf",
  red            = "#fd6883",
  baby_pink      = "#f38d70",
  pink           = "#fd6883",
  line           = "#3b3232",
  green          = "#adda78", -- Function green
  vibrant_green  = "#b9e28c",
  blue           = "#85dacc",
  nord_blue      = "#78dce8",
  yellow         = "#f9cc6c",
  sun            = "#ffd866",
  purple         = "#a8a9eb",
  dark_purple    = "#bf9fee",
  teal           = "#85dacc",
  orange         = "#f38d70",
  cyan           = "#78dce8",
  statusline_bg  = "#261f1f",
  lightbg        = "#3b3232",
  pmenu_bg       = "#2c2525",
  folder_bg      = "#85dacc",
}

M.base_16 = {
  base00 = "#2c2525", -- Background
  base01 = "#403838", 
  base02 = "#4d4343", 
  base03 = "#72696a", -- Muted Comments (Fixed)
  base04 = "#948a8b", 
  base05 = "#fff8f9", -- Main Text
  base06 = "#fff1f3", 
  base07 = "#ffffff", 
  base08 = "#fd6883", -- Variables (Red)
  base09 = "#f38d70", -- Constants (Orange)
  base0A = "#f9cc6c", -- Classes (Yellow)
  base0B = "#f9cc6c", -- Strings (Yellow)
  base0C = "#85dacc", -- Type/Regex (Cyan)
  base0D = "#adda78", -- Functions (Green - Fixed)
  base0E = "#a8a9eb", -- Keywords (Purple)
  base0F = "#fd6883",
}

M.type = "dark"

M = require("base46").override_theme(M, "monokai-pro-ristretto")

return M
