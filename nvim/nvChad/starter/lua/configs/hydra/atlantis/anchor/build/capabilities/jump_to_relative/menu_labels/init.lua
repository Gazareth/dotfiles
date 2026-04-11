-- Jump hint target names: ordered strategies (assignment → function → text fallback).
local assignment = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels.strategies.assignment")
local fallback = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels.strategies.fallback")
local fn_strategy = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels.strategies.function")

local M = {}

local MAX_CHARS = 24

-- Order matches probe specialization (structured fields before raw text).
local strategies = {
  assignment,
  fn_strategy,
  fallback,
}

local function truncate(str, max_chars)
  if type(str) ~= "string" or str == "" then
    return str or ""
  end
  local n = vim.fn.strchars(str)
  if n <= max_chars then
    return str
  end
  return vim.fn.strcharpart(str, 0, max_chars) .. "..."
end

local function format_name(node_info, parsed)
  for _, strat in ipairs(strategies) do
    local name = strat.try(parsed, node_info)
    if type(name) == "string" and name ~= "" then
      return name
    end
  end
  return "node"
end

--- Quoted target name for jump hint lines (ASCII in source; hint layer maps _ for Hydra).
function M.quoted_target(node_info, parsed)
  local name = truncate(format_name(node_info, parsed), MAX_CHARS)
  name = name:gsub('"', "'")
  return '"' .. name .. '"'
end

return M
