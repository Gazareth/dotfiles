local anchor_actionable = require("configs.hydra.atlantis.prepare.anchor_point.build.actionable")
local build_node_info = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.node_info").build_node_info
local salvage_target = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.salvage_target")
local treesitter_config = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.config")

local jump_targets = {}

local function walk_to_sibling(node, prev)
  local cur = node
  while cur do
    local t
    if prev then
      t = cur:prev_named_sibling()
    else
      t = cur:next_named_sibling()
    end
    if t then return t end
    local p = cur:parent()
    if not p or p:named_child_count() > 1 then break end
    cur = p
  end
end

local function find_sibling_container(node)
  local cur = node
  while true do
    local p = cur:parent()
    if not p or p:named_child_count() > 1 then return p or cur end
    cur = p
  end
end

local function extreme_sibling(node, first)
  local container = find_sibling_container(node)
  local n = container:named_child_count()
  if n <= 1 then return nil end
  local candidate = first and container:named_child(0) or container:named_child(n - 1)
  -- Avoid wrapping to the container child that already contains the current node.
  -- Walk up from node to find which container child we're under.
  local cur = node
  while cur do
    local p = cur:parent()
    if p == container then
      if cur == candidate then return nil end
      break
    end
    cur = p
  end
  return candidate
end

local relation_resolvers = {
  parent        = function(n) return n:parent() or n:prev_named_sibling() end,
  prev_sibling  = function(n) return walk_to_sibling(n, true) end,
  next_sibling  = function(n) return walk_to_sibling(n, false) end,
  first_sibling = function(n) return extreme_sibling(n, true) end,
  last_sibling  = function(n) return extreme_sibling(n, false) end,
  child         = function(n) return n:named_child(0) end,
}

function jump_targets.resolve(selected_node_info, relation)
  if not selected_node_info or not selected_node_info.node then
    return nil
  end

  local resolver = relation_resolvers[relation]
  if not resolver then return nil end

  local node = selected_node_info.node
  local target = resolver(node)

  if not target then
    return nil
  end

  target = salvage_target.focus_node(target, selected_node_info.bufnr, nil)

  return build_node_info({
    bufnr = selected_node_info.bufnr,
    node = target,
  })
end

--- Walk parents from the current anchor node to the first language-mapped actionable node (next anchor point up).
function jump_targets.resolve_next_highest_anchor(selected_node_info)
  if not selected_node_info or not selected_node_info.node then
    return nil
  end
  local cfg = treesitter_config.get()
  local resolve_options = anchor_actionable.resolve_options_from_config(cfg)
  local cur = selected_node_info.node:parent()
  while cur do
    local ni = build_node_info({
      bufnr = selected_node_info.bufnr,
      node = cur,
    })
    if ni then
      local ok, _ = anchor_actionable.check(ni, resolve_options)
      if ok then
        local focused = salvage_target.focus_node(cur, selected_node_info.bufnr, nil)
        return build_node_info({
          bufnr = selected_node_info.bufnr,
          node = focused,
        })
      end
    end
    cur = cur:parent()
  end
  return nil
end

function jump_targets.is_document_root(node_info)
  local node = node_info and node_info.node
  if not node then
    return false
  end
  return node:parent() == nil
end

function jump_targets.jump_action(target_node_info)
  return function()
    if not target_node_info then
      return
    end

    local row = (target_node_info.start_row or 0) + 1
    local col = (target_node_info.start_col or 0)
    pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
  end
end

return jump_targets
