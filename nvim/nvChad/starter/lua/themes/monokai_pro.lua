local M = {}

M.base_30 = {
  white = "#fcfcfa",
  darker_black = "#221f23",
  black = "#282529",
  black2 = "#2e2b2f", --  nvim bg
  one_bg = "#322f33",
  one_bg2 = "#3b383c",
  one_bg3 = "#434044",
  grey = "#504d51",
  grey_fg = "#5a575b",
  grey_fg2 = "#646165",
  light_grey = "#6c696d",
  -- lighter_grey = "#989896",
  red = "#ff6188",
  baby_pink = "#ff7097",
  pink = "#ff98bf",
  line = "#373438", -- for lines like vertsplit
  green = "#a9dc76", -- Command mode
  vibrant_green = "#afe27c",
  blue = "#9dc7ff",
  nord_blue = "#95bff7", -- Normal mode
  yellow = "#ffd866",
  sun = "#ffe06e",
  purple = "#5f5f87",
  dark_purple = "#ab9df2", -- Insert mode
  teal = "#89dcc0",
  orange = "#fc9867",
  cyan = "#78dce8", -- Visual mode
  statusline_bg = "#2c292d",
  lightbg = "#39363a",
  pmenu_bg = "#a9dc76",
  folder_bg = "#9dc7ff",
}

M.base_16 = {
  base00 = "#282529",
  base01 = "#3a373a",
  base02 = "#423f42",
  base03 = "#727072",
  base04 = "#696769",
  base05 = "#fcfcfa",  -- Cursor
  base06 = "#727072",
  base07 = "#696769",
  base08 = "#fcfcfa",
  base09 = "#ab9df2",
  base0A = "#78dce8",
  base0B = "#ffd866",
  base0C = "#fc9867",
  base0D = "#a9dc76",
  base0E = "#ff6188",
  base0F = "#939293",
}

M.type = "dark";

M = require("base46").override_theme(M, "monokai-pro")

return M
