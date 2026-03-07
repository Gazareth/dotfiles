-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua

-- Path to overriding theme and highlights files
local highlights = require "highlights"

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "monokai_pro_ristretto",
	theme_toggle = { "monokai_pro_ristretto", "one_light" },
  
	hl_override = highlights.override,
	hl_add = highlights.add,

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

M.ui = {
  tabufline = {
    enabled= false
  }
}

return M
