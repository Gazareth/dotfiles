local anchor_actionable = require("configs.hydra.atlantis.anchor.build.find_from_node.actionable")
local build_node_info = require("configs.hydra.atlantis.anchor.probe.treesitter.node_info").build_node_info
local title_const = require("configs.hydra.atlantis.menu.components.title.constants")
local treesitter_config = require("configs.hydra.atlantis.anchor.probe.treesitter.config")

local M = {}

function M.parse_tree_root(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return nil
  end
  local trees = parser:parse()
  local tree = trees and trees[1]
  if not tree then
    return nil
  end
  return tree:root()
end

local function safe_root(bufnr)
  return M.parse_tree_root(bufnr)
end

local function qualifies(node)
  return node and node:named_child_count() >= 2
end

-- Function-like TS node types: if such a node appears on the path to the parse root
-- and its parent is *not* the root, the anchor lives inside a nested callable scope.
local FN_ANCESTOR_TYPES = {
  function_declaration = true,
  function_definition = true,
  function_expression = true,
  arrow_function = true,
  method_definition = true,
  ["function"] = true,
}

local function has_nested_function_ancestor(anchor_node, root)
  if not anchor_node or not root then
    return false
  end
  local n = anchor_node
  while n do
    if n:id() == root:id() then
      return false
    end
    local t = n:type()
    if FN_ANCESTOR_TYPES[t] then
      local p = n:parent()
      if p and p:id() ~= root:id() then
        return true
      end
    end
    n = n:parent()
  end
  return false
end

local BODY_FIELD = "body"

local function cursor_descendant_of(cursor_node, ancestor)
  if not cursor_node or not ancestor then
    return false
  end
  local n = cursor_node
  while n do
    if n:id() == ancestor:id() then
      return true
    end
    n = n:parent()
  end
  return false
end

--- If the cursor is inside the `body` field of a callable whose parent is the parse root, return
--- that body node so the outline indexes statements inside the function — not the whole file.
--- Signature / name / params (nodes not under `body`) keep file-root navigation.
local function body_container_if_cursor_in_top_level_callable(cursor_node, root)
  if not cursor_node or not root then
    return nil
  end
  local n = cursor_node
  while n and n:id() ~= root:id() do
    local t = n:type()
    if FN_ANCESTOR_TYPES[t] then
      local p = n:parent()
      if p and p:id() == root:id() then
        local ok, body = pcall(function()
          return n:child_by_field_name(BODY_FIELD)
        end)
        if ok and body and cursor_descendant_of(cursor_node, body) then
          return body
        end
        return nil
      end
    end
    n = n:parent()
  end
  return nil
end

local function notify_container(bufnr, node)
  local ni = build_node_info({ bufnr = bufnr, node = node })
  if not ni then
    vim.notify("Atlantis: Walked up 3 or more layers to find (unknown).", vim.log.levels.INFO)
    return
  end
  local cfg = treesitter_config.get()
  local resolve_options = anchor_actionable.resolve_options_from_config(cfg)
  local ok, semantic = anchor_actionable.check(ni, resolve_options)
  local kind = type(semantic) == "table" and semantic.node_kind or nil
  local icon = title_const.resolve_icon(kind, ni.node_type)
  local bracket = title_const.resolve_label(kind, ni.node_type)
  local name = vim.trim(ni.text or "")
  if name == "" then
    name = bracket
  end
  local label = string.format("%s %s %s", icon, bracket, name):gsub("^%s+", "")
  vim.notify("Atlantis: Walked up 3 or more layers to find " .. label .. ".", vim.log.levels.INFO)
end

--- Outline container for navigation mode when not using file-root index.
--- File-scoped anchors (top-level statements, top-level functions): the natural
--- "collection" for navigation is usually the parse tree root — same outcome as "Top level..." (H).
--- Exception: cursor inside a top-level callable's **body** uses that body node so nav matches
--- local scope (e.g. after "Jump to body"). Signature-only positions still use the file root.
--- Inside a nested function/method (callable whose parent is not the root), use the
--- semantic anchor node as the outline container.
--- @return TSNode|nil container_node
--- @return boolean is_parse_root
function M.container_for_nav_mode(anchor_ctx, bufnr, cursor_node)
  anchor_ctx = type(anchor_ctx) == "table" and anchor_ctx or {}
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local anchor_ni = anchor_ctx.anchor_node_info
  local anchor_node = anchor_ni and anchor_ni.node
  if not anchor_node then
    return M.resolve_anchor_container(bufnr, cursor_node)
  end
  local root = M.parse_tree_root(bufnr)
  if not root then
    return M.resolve_anchor_container(bufnr, cursor_node)
  end
  if anchor_node:id() == root:id() then
    return root, true
  end
  if not has_nested_function_ancestor(anchor_node, root) then
    local body_scope = body_container_if_cursor_in_top_level_callable(cursor_node, root)
    if body_scope then
      return body_scope, false
    end
    return root, true
  end
  return anchor_node, false
end

--- True when the anchor is file-scoped (parse root or top-level statement), i.e. not inside a
--- nested callable whose parent is not the parse root. Aligns with when `container_for_nav_mode`
--- uses the parse tree root as the outline container.
--- @param anchor_node userdata|nil
--- @param bufnr integer
function M.is_file_scope_anchor(anchor_node, bufnr)
  local root = M.parse_tree_root(bufnr)
  if not anchor_node or not root then
    return false
  end
  if anchor_node:id() == root:id() then
    return true
  end
  return not has_nested_function_ancestor(anchor_node, root)
end

--- @return TSNode|nil container_node
--- @return boolean is_parse_root
function M.resolve_anchor_container(bufnr, cursor_node)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not cursor_node then
    local root = safe_root(bufnr)
    return root, root ~= nil
  end

  local root = safe_root(bufnr)
  local failures = 0
  local n = cursor_node

  while n do
    if qualifies(n) then
      if failures >= 3 then
        notify_container(bufnr, n)
      end
      local is_root = root and n:id() == root:id()
      return n, is_root
    end
    failures = failures + 1
    n = n:parent()
  end

  if root then
    if failures >= 3 then
      notify_container(bufnr, root)
    end
    return root, true
  end

  return nil, false
end

return M
