-- Jump hint target names: ordered strategies (assignment → function → text fallback).
local assignment = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.labels.label_strategies.assignment")
local fallback = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.labels.label_strategies.fallback")
local fn_strategy = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.labels.label_strategies.function")
local probe = require("configs.hydra.atlantis.prepare.anchor_point.probe")

local M = {}

local MAX_CHARS = 16

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

--- Short display name (same pipeline as quoted_target, without wrapping quotes).
function M.display_name_for_node(node_info, parsed)
  if type(node_info) ~= "table" then
    return "?"
  end
  local p = type(parsed) == "table" and parsed or probe.parse(node_info)
  local name = truncate(format_name(node_info, p), MAX_CHARS)
  name = name:gsub('"', "'")
  return name
end

--- Quoted target name for jump hint lines (ASCII in source; hint layer maps _ for Hydra).
function M.quoted_target(node_info, parsed)
  local name = M.display_name_for_node(node_info, parsed)
  return '"' .. name .. '"'
end

--- Optional `parsed` from find_from_node (probe.parse); otherwise parses here.
function M.quoted_for_node(node_info, parsed)
  if type(node_info) ~= "table" then
    return nil
  end
  local p = type(parsed) == "table" and parsed or probe.parse(node_info)
  return M.quoted_target(node_info, p)
end

--- Parallel to candidate chain indices: quoted Hydra fragments for the context “higher” row.
function M.jump_labels_for_candidates(candidates)
  local labels = {}
  for i, c in ipairs(candidates or {}) do
    if type(c) == "table" and type(c.node_info) == "table" then
      labels[i] = M.quoted_for_node(c.node_info, c.parsed)
    end
  end
  return labels
end

return M
