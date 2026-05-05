local node_kinds = require("configs.hydra.atlantis-deprecated.schema.constants").node_kinds

local M = {}

local function is_comment_target(parsed, node_type)
  if type(parsed) == "table" and parsed.semantic_kind == node_kinds.comment then
    return true
  end
  if type(node_type) == "string" and node_type:lower():find("comment", 1, true) then
    return true
  end
  return false
end

function M.strip_comment_leaders(text)
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

function M.lhs_identifier_from_assignment_line(text)
  if type(text) ~= "string" then
    return nil
  end
  local t = vim.trim(text)
  while true do
    local n = t:gsub("^local%s+", "")
    if n == t then
      break
    end
    t = vim.trim(n)
  end
  t = vim.trim(t:gsub("^export%s+", ""))
  return t:match("^([%a_][%w_]*)%s*=[^=]")
end

function M.compact_code_snippet(text)
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

  local assign_lhs = M.lhs_identifier_from_assignment_line(t)
  if assign_lhs then
    return assign_lhs
  end

  -- `local a, b =` / `a, b =` — first binding only (single-line sibling labels).
  if t:find("=", 1, true) and not t:match("^function%s+") then
    local first = t:match("^([%a_][%w_]*)%s*,")
    if first then
      return first
    end
  end

  return t
end

function M.scrub_preview_text(text, parsed, node_type)
  if type(text) ~= "string" or text == "" then
    return text
  end
  text = vim.trim(text:gsub("\n+", " "))
  if is_comment_target(parsed, node_type) then
    return M.strip_comment_leaders(text)
  end
  return M.compact_code_snippet(text)
end

return M
