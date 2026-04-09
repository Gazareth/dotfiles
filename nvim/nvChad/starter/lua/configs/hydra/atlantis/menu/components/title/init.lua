-- Public API for menu title building; combines badges, extraction, and assembly
local badges  = require("configs.hydra.atlantis.menu.components.title.badges")
local extract = require("configs.hydra.atlantis.menu.components.title.extract")
local builder = require("configs.hydra.atlantis.menu.components.title.builder")

local M = {}

-- Badge resolution
M.resolve_label = badges.resolve_label
M.resolve_icon  = badges.resolve_icon

-- Text extraction
M.truncate                = extract.truncate
M.extract_comment_name    = extract.extract_comment_name
M.extract_for_name        = extract.extract_for_name
M.extract_if_name         = extract.extract_if_name
M.extract_assignment_name = extract.extract_assignment_name

-- Title assembly
M.build             = builder.build
M.build_from_parsed = builder.build_from_parsed

return M
