-- Resolve preferred cursor anchor position for menu open behavior
local node_common = require("configs.hydra.atlantis.prepare.anchor_point.probe.common.node")
local treesitter_constants = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.constants")
local build_node_info = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.node_info").build_node_info
local parse_function = require("configs.hydra.atlantis.prepare.anchor_point.probe.node_kinds.function").parse_function
local body_lib = require("configs.hydra.atlantis.prepare.anchor_point.probe.node_kinds.function.lib.body")
local function_constants = require("configs.hydra.atlantis.prepare.anchor_point.probe.node_kinds.function.lib.constants")

local supported_nodes = treesitter_constants.supported_nodes
local parameter_container_types = treesitter_constants.parameter_container_types

local M = {}

local function binary_left_operand(node)
  if not node then
    return nil
  end
  local left = node_common.get_field_node(node, "left")
  if left then
    return left
  end
  if node:named_child_count() >= 1 then
    return node:named_child(0)
  end
  return nil
end

local function drill_first_named_leaf_start(node)
  if not node then
    return nil
  end
  local cur = node
  while cur:named_child_count() >= 1 do
    cur = cur:named_child(0)
  end
  local row, col = cur:start()
  return { row = row, col = col }
end

local function function_name_target_from_declaration(fn_node, bufnr)
  local ni = build_node_info({ bufnr = bufnr, node = fn_node })
  if not ni then
    return nil
  end
  local parsed_fn = parse_function(ni)
  local t = parsed_fn.targets and parsed_fn.targets.function_name
  if type(t) == "table" and type(t.row) == "number" and type(t.col) == "number" then
    return t
  end
  return nil
end

-- Handlers for depth-1 ancestor walk. Each receives (cur, cursor_node_info, bufnr) and
-- returns a {row,col} target or nil. Returning nil from a handler means "no result from
-- this node type — continue walking". Handlers that want to abort the walk (no target
-- anywhere up this path) return false.
local function handle_comment(cur, cursor_node_info, _bufnr)
  local c = cursor_node_info.cursor
  if type(c) == "table" and type(c.row) == "number" and type(c.col) == "number" then
    return { row = c.row - 1, col = c.col }
  end
  return false
end

local function handle_return_statement(cur, cursor_node_info, bufnr)
  if cur:named_child_count() >= 1 then
    local inner = drill_first_named_leaf_start(cur:named_child(0))
    if inner then
      return inner
    end
  end
  local fn_node = node_common.find_ancestor_of_types(
    cursor_node_info.node, function_constants.function_like_types, { include_self = true }
  )
  if fn_node then
    return function_name_target_from_declaration(fn_node, bufnr)
  end
  return false
end

local function handle_parameter_container(cur, cursor_node_info, bufnr)
  local first = cur:named_child_count() >= 1 and cur:named_child(0) or nil
  if first then
    local row, col = first:start()
    return { row = row, col = col }
  end
  local fn_node = node_common.find_ancestor_of_types(
    cursor_node_info.node, function_constants.function_like_types, { include_self = true }
  )
  if fn_node then
    return function_name_target_from_declaration(fn_node, bufnr)
  end
  return false
end

-- Fallback: cursor is inside a function body — snap to the first statement or the
-- function name declaration.
local function handle_function_body_fallback(cursor_node_info, bufnr)
  local fn_node = node_common.find_ancestor_of_types(
    cursor_node_info.node, function_constants.function_like_types, { include_self = true }
  )
  if fn_node then
    local body = body_lib.find_body_block(fn_node)
    if body and node_common.is_descendant_of(cursor_node_info.node, body) then
      if body:named_child_count() >= 1 then
        local stmt = body:named_child(0)
        local row, col = stmt:start()
        return { row = row, col = col }
      end
      return function_name_target_from_declaration(fn_node, bufnr)
    end
  end
  return nil
end

-- Single-pass ancestor walk: first matching handler wins.
-- Returning false from a handler means "abort — no target on this path".
local depth1_handlers = {
  comment          = handle_comment,
  return_statement = handle_return_statement,
}

-- depth >= 1: nested "natural" cursor from cursor chain (selection may still be outer anchor).
local function resolve_menu_depth_one(anchor_node_info, cursor_node_info)
  if not cursor_node_info or not cursor_node_info.node then
    return nil
  end

  local bufnr = anchor_node_info and anchor_node_info.bufnr or 0
  local cur = cursor_node_info.node

  while cur do
    local handler = depth1_handlers[cur:type()]
    if handler then
      local result = handler(cur, cursor_node_info, bufnr)
      -- false = handler matched but found no target; stop walking
      if result == false then return nil end
      if result then return result end
    end
    if parameter_container_types[cur:type()] == true then
      local result = handle_parameter_container(cur, cursor_node_info, bufnr)
      if result == false then return nil end
      if result then return result end
    end
    cur = cur:parent()
  end

  return handle_function_body_fallback(cursor_node_info, bufnr)
end

-- Resolve preferred jump target within selected anchor
local function resolve_anchor_target(parsed, anchor_node_info, cursor_node_info, opts)
  local depth = 0
  if type(opts) == "table" and type(opts.depth) == "number" then
    depth = opts.depth
  end

  if depth >= 1 then
    local d1 = resolve_menu_depth_one(anchor_node_info, cursor_node_info)
    if type(d1) == "table" then
      return d1
    end
  end

  if type(parsed) ~= "table" then
    return nil
  end

  local targets = type(parsed.targets) == "table" and parsed.targets or nil

  if parsed.node_kind == supported_nodes.fn and type(targets) == "table" and type(targets.function_name) == "table" then
    return targets.function_name
  end

  if parsed.node_kind == supported_nodes.assignment and type(targets) == "table" and type(targets.left) == "table" then
    return targets.left
  end

  if parsed.node_kind == supported_nodes.binary_expression and type(targets) == "table" and type(targets.left) == "table" then
    return targets.left
  end

  -- Boolean condition: walk from the cursor node so we still find `binary_expression` when the chosen anchor is ERROR/chunk.
  if cursor_node_info and cursor_node_info.node then
    local bn = cursor_node_info.node
    while bn do
      if bn:type() == "binary_expression" then
        local left = binary_left_operand(bn)
        if left then
          local row, col = left:start()
          return { row = row, col = col }
        end
        break
      end
      bn = bn:parent()
    end
  end

  if type(anchor_node_info) == "table"
    and anchor_node_info.node
    and parameter_container_types[anchor_node_info.node_type] == true then
    local first_named = anchor_node_info.node:named_child(0)
    if first_named then
      local row, col = first_named:start()
      return {
        row = row,
        col = col,
      }
    end
  end

  return nil
end

-- Clone anchor info with cursor start aligned to preferred target
--- @param cursor_node_info table|nil optional; when set, enables boolean LHS snap from cursor chain
--- @param opts table|nil optional anchor_build opts (`depth` for nested menu positioning)
function M.build_positioned_anchor(anchor_node_info, parsed_anchor, cursor_node_info, opts)
  if type(anchor_node_info) ~= "table" then
    return anchor_node_info
  end

  local target = resolve_anchor_target(parsed_anchor, anchor_node_info, cursor_node_info, opts)
  if type(target) ~= "table" then
    return anchor_node_info
  end

  local positioned = vim.tbl_extend("force", {}, anchor_node_info)
  if type(target.row) == "number" then
    positioned.start_row = target.row
  end
  if type(target.col) == "number" then
    positioned.start_col = target.col
  end

  return positioned
end

return M
