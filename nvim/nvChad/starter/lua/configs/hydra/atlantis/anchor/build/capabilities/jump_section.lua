local build_node_info = require("configs.hydra.atlantis.anchor.probe.treesitter.node_info").build_node_info
local parse_node = require("configs.hydra.atlantis.anchor.probe")
local menu_schema = require("configs.hydra.atlantis.schema.menu")
local title_const = require("configs.hydra.atlantis.menu.components.title.constants")
local node_kinds = require("configs.hydra.atlantis.schema.constants").node_kinds

local M = {}

local jump_cfg = menu_schema.jump

local JUMP_LABEL_MAX_CHARS = 24

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

local function scrub_jump_preview_text(text, parsed, node_type)
  if type(text) ~= "string" or text == "" then
    return text
  end
  text = vim.trim(text:gsub("\n+", " "))
  if is_comment_target(parsed, node_type) then
    return strip_comment_leaders(text)
  end
  return compact_code_snippet(text)
end

local function truncate_label_text(str, max_chars)
  if type(str) ~= "string" or str == "" then
    return str or ""
  end
  local n = vim.fn.strchars(str)
  if n <= max_chars then
    return str
  end
  return vim.fn.strcharpart(str, 0, max_chars) .. "..."
end

local function format_node_name(node_info, parsed)
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
  text = scrub_jump_preview_text(text, parsed, node_type)
  if text == "" then
    return type(parsed) == "table" and tostring(parsed.display_name or parsed.node_type or "node") or "node"
  end

  return text
end

local function build_anchor_label(node_info, parsed)
  local semantic = type(parsed) == "table" and parsed.semantic_kind or nil
  local node_type = type(parsed) == "table" and parsed.node_type or nil
  local icon = title_const.resolve_icon(semantic, node_type)
  local name = truncate_label_text(format_node_name(node_info, parsed), JUMP_LABEL_MAX_CHARS)
  if name == "" then
    return icon
  end
  return icon .. " " .. name
end

local function jump_to_node_info(target_node_info)
  return function()
    if not target_node_info then
      return
    end

    local row = (target_node_info.start_row or 0) + 1
    local col = target_node_info.start_col or 0
    pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
  end
end

local function resolve_target_node_info(selected_node_info, relation)
  if not selected_node_info or not selected_node_info.node then
    return nil
  end

  local node = selected_node_info.node
  local target = nil

  if relation == "parent" then
    target = node:parent()
    if not target then
      target = node:prev_named_sibling()
    end
  elseif relation == "prev_sibling" then
    target = node:prev_named_sibling()
  elseif relation == "next_sibling" then
    target = node:next_named_sibling()
  elseif relation == "child" then
    target = node:named_child(0)
  end

  if not target then
    return nil
  end

  return build_node_info({
    bufnr = selected_node_info.bufnr,
    node = target,
  })
end

local function is_document_root_target(node_info)
  local node = node_info and node_info.node
  if not node then
    return false
  end
  return node:parent() == nil
end

local function build_target_jump_item(key, icon, target_node_info)
  if not target_node_info then
    return nil
  end

  local target_parsed = parse_node(target_node_info)
  return {
    key = key,
    icon = icon,
    label = build_anchor_label(target_node_info, target_parsed),
    action = jump_to_node_info(target_node_info),
  }
end

local function append_group_heading(items, group_id)
  local label = jump_cfg.group_labels and jump_cfg.group_labels[group_id]
  if type(label) ~= "string" or label == "" then
    return
  end
  items[#items + 1] = { separator = true }
  items[#items + 1] = { separator = true, label = label }
  items[#items + 1] = { separator = true }
end

local function append_relation_items(items, selected_node_info)
  local last_group = nil
  for _, row in ipairs(jump_cfg.items or {}) do
    if type(row.relation) == "string" then
      if row.group ~= last_group then
        append_group_heading(items, row.group)
        last_group = row.group
      end
      local target = resolve_target_node_info(selected_node_info, row.relation)
      local item
      if row.relation == "parent" and target and is_document_root_target(target) then
        local dr = jump_cfg.document_root_jump
        item = {
          key = row.key,
          icon = type(dr) == "table" and dr.icon or "⇪",
          label = type(dr) == "table" and dr.label or "Go to top",
          action = jump_to_node_info(target),
        }
      else
        item = build_target_jump_item(row.key, row.icon, target)
      end
      if item then
        items[#items + 1] = item
      end
    end
  end
end

local function context_row_spec(which)
  for _, row in ipairs(jump_cfg.items or {}) do
    if row.context == which then
      return row
    end
  end
  return nil
end

local function append_context_items(items, candidates, selected_index)
  if type(selected_index) ~= "number" then
    return
  end

  local higher_spec = context_row_spec("higher")
  local lower_spec = context_row_spec("lower")
  local has_context_items = false

  if selected_index < #candidates then
    local higher = candidates[selected_index + 1]
    local higher_parsed = higher and parse_node(higher.node_info) or nil
    if not has_context_items then
      append_group_heading(items, "context")
      has_context_items = true
    end
    items[#items + 1] = {
      key = higher_spec and higher_spec.key or "h",
      icon = higher_spec and higher_spec.icon or "⬆",
      label = build_anchor_label(higher and higher.node_info, higher_parsed),
      action = jump_to_node_info(higher and higher.node_info),
    }
  end

  if selected_index > 1 then
    local lower = candidates[selected_index - 1]
    local lower_parsed = lower and parse_node(lower.node_info) or nil
    if not has_context_items then
      append_group_heading(items, "context")
      has_context_items = true
    end
    items[#items + 1] = {
      key = lower_spec and lower_spec.key or "l",
      icon = lower_spec and lower_spec.icon or "⬇",
      label = build_anchor_label(lower and lower.node_info, lower_parsed),
      action = jump_to_node_info(lower and lower.node_info),
    }
  end
end

function M.build(anchor_node_info, find_result)
  local items = {}
  local candidates = type(find_result) == "table" and find_result.candidates or {}
  local selected_index = type(find_result) == "table" and find_result.selected_candidate_index or nil

  append_relation_items(items, anchor_node_info)
  append_context_items(items, candidates, selected_index)

  return {
    title = jump_cfg.title,
    items = items,
  }
end

return M
