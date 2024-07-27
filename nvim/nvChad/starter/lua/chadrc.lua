-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua

-- Path to overriding theme and highlights files
local highlights = require "highlights"

---@type ChadrcConfig
local M = {}

M.ui = {
	theme = "monokai_pro",
	theme_toggle = { "monokai_pro", "one_light" },
  
	hl_override = highlights.override,
	hl_add = highlights.add,

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

return M
