-- Top-level actionable nodes only (direct children of the Treesitter root), grouped by semantic node kind.
local anchor_actionable = require("configs.hydra.atlantis.anchor.build.find_from_node.actionable")
local build_node_info = require("configs.hydra.atlantis.anchor.probe.treesitter.node_info").build_node_info
local nk = require("configs.hydra.atlantis.schema.constants").node_kinds
local probe = require("configs.hydra.atlantis.anchor.probe")
local treesitter_config = require("configs.hydra.atlantis.anchor.probe.treesitter.config")

local M = {}

local function safe_root(bufnr)
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

--- File outline: skip standalone lexical nodes (still actionable elsewhere in Treewalker).
local function include_in_file_nav(semantic)
  if type(semantic) ~= "table" then
    return false
  end
  local kind = semantic.node_kind
  if kind == nk.identifier or kind == nk.string or kind == nk.comment then
    return false
  end
  return true
end

local function sort_by_pos(a, b)
  if a.row ~= b.row then
    return a.row < b.row
  end
  return a.col < b.col
end

--- Consider a single node for the outline (used for root-level children only).
local function push_if_actionable(bufnr, node, cfg, resolve_options, by_kind)
  if not node then
    return
  end
  local node_info = build_node_info({ bufnr = bufnr, node = node })
  if not node_info then
    return
  end
  local ok, semantic = anchor_actionable.check(node_info, resolve_options)
  if not ok or not semantic or not include_in_file_nav(semantic) then
    return
  end
  local kind = semantic.node_kind
  if type(kind) ~= "string" or kind == "" then
    kind = nk.unknown
  end
  if type(by_kind[kind]) ~= "table" then
    by_kind[kind] = {}
  end
  local row, col = node:start()
  local list = by_kind[kind]
  list[#list + 1] = {
    node = node,
    node_info = node_info,
    parsed = probe.parse(node_info, { semantic = semantic, config = cfg }),
    semantic = semantic,
    row = row,
    col = col,
  }
end

local function scan_top_level(bufnr, root, cfg, resolve_options, by_kind)
  local n = root:named_child_count()
  for i = 0, n - 1 do
    push_if_actionable(bufnr, root:named_child(i), cfg, resolve_options, by_kind)
  end
end

--- @param kind_order string[] display order; buckets may omit empty kinds
--- @return { by_kind: table<string, table[]>, kind_order: string[] }
function M.build(bufnr, kind_order)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  kind_order = type(kind_order) == "table" and kind_order or {}

  local by_kind = {}
  local root = safe_root(bufnr)
  if root then
    local cfg = treesitter_config.get()
    local resolve_options = anchor_actionable.resolve_options_from_config(cfg)
    scan_top_level(bufnr, root, cfg, resolve_options, by_kind)
  end

  for _, list in pairs(by_kind) do
    if type(list) == "table" then
      table.sort(list, sort_by_pos)
    end
  end

  return { by_kind = by_kind, kind_order = kind_order }
end

function M.cursor_pos0()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return line - 1, col
end

function M.next_index(list, row0, col0)
  if type(list) ~= "table" or #list == 0 then
    return nil
  end
  for i, e in ipairs(list) do
    if e.row > row0 or (e.row == row0 and e.col > col0) then
      return i
    end
  end
  return 1
end

return M
