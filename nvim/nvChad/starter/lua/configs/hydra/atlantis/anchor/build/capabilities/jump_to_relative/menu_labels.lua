local title_const = require("configs.hydra.atlantis.menu.components.title.constants")
local node_kinds = require("configs.hydra.atlantis.schema.constants").node_kinds

local M = {}

local MAX_CHARS = 24

local function is_comment_target(parsed, node_type)
  if type(parsed) == "table" and parsed.semantic_kind == node_kinds.comment then
    return true
  end
  if type(node_type) == "string" and node_type:lower():find("comment", 1, true) then
    return true
  end
  return false
end

local function strip_comment_leaders(text)
  local t = vim.trim(text)
  t = t:gsub("^/%*%*?%s*", "")
  t = t:gsub("^//%s*", "")
  t = t:gsub("^#+%s*", "")
  while true do
    local n = t:gsub("^%-%-+%s*", "")
    if n == t then
      break
    end
    t = vim.trim(n)
  end
  t = t:gsub("%s*%*/%s*$", "")
  return vim.trim(t)
end

local function compact_code_snippet(text)
  local t = vim.trim(text)
  while true do
    local n = t:gsub("^local%s+", "")
    if n == t then
      break
    end
    t = vim.trim(n)
  end
  t = vim.trim(t:gsub("^export%s+", ""))

  local fn_only = t:match("^function%s+([%a_][%w_]*)")
  if fn_only then
    return fn_only
  end

  return t
end

local function scrub_preview_text(text, parsed, node_type)
  if type(text) ~= "string" or text == "" then
    return text
  end
  text = vim.trim(text:gsub("\n+", " "))
  if is_comment_target(parsed, node_type) then
    return strip_comment_leaders(text)
  end
  return compact_code_snippet(text)
end

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
  if type(parsed) == "table" and type(parsed.function_name) == "string" then
    local function_name = vim.trim(parsed.function_name)
    if function_name ~= "" and function_name ~= "anonymous" then
      return function_name
    end
  end

  local text = type(parsed) == "table" and parsed.text or nil
  if type(text) ~= "string" or text == "" then
    text = node_info and node_info.text or ""
  end

  local node_type = type(parsed) == "table" and parsed.node_type or (node_info and node_info.node_type) or nil
  text = scrub_preview_text(text, parsed, node_type)
  if text == "" then
    return type(parsed) == "table" and tostring(parsed.display_name or parsed.node_type or "node") or "node"
  end

  return text
end

function M.build_label(node_info, parsed)
  local semantic = type(parsed) == "table" and parsed.semantic_kind or nil
  local node_type = type(parsed) == "table" and parsed.node_type or nil
  local icon = title_const.resolve_icon(semantic, node_type)
  local name = truncate(format_name(node_info, parsed), MAX_CHARS)
  if name == "" then
    return icon
  end
  return icon .. " " .. name
end

return M
