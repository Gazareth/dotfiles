local anchor_actionable = require("configs.hydra.atlantis.prepare.anchor_point.build.actionable")
local build_node_info = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.node_info").build_node_info
local salvage_target = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.salvage_target")
local treesitter_config = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.config")

local jump_targets = {}

local function is_container(node, bufnr, resolve_options)
  if not node then return false end
  local ni = build_node_info({ bufnr = bufnr, node = node })
  return ni ~= nil and anchor_actionable.is_container(ni, resolve_options)
end

local function find_nearest_container(node, bufnr, resolve_options)
  local cur = node:parent()
  while cur do
    if is_container(cur, bufnr, resolve_options) then return cur end
    cur = cur:parent()
  end
  local root = node
  while root:parent() do root = root:parent() end
  return root
end

local function collect_siblings(container, bufnr, resolve_options)
  local siblings = {}
  local function walk(n)
    for i = 0, n:named_child_count() - 1 do
      local child = n:named_child(i)
      local ni = build_node_info({ bufnr = bufnr, node = child })
      local ok, sem = anchor_actionable.check(ni, resolve_options)
      if ok then
        table.insert(siblings, child)
      else
        if not is_container(child, bufnr, resolve_options) then
          walk(child)
        end
      end
    end
  end
  walk(container)
  return siblings
end

local function get_siblings_and_index(node, bufnr)
  local cfg = treesitter_config.get()
  local resolve_options = anchor_actionable.resolve_options_from_config(cfg)
  
  local container = find_nearest_container(node, bufnr, resolve_options)
  local list = collect_siblings(container, bufnr, resolve_options)
  
  local current_index = nil
  for i, s in ipairs(list) do
    if s:id() == node:id() then
      current_index = i
      break
    end
  end

  if not current_index then
    for i, s in ipairs(list) do
      local cur = node:parent()
      while cur and cur:id() ~= container:id() do
        if cur:id() == s:id() then
          current_index = i
          break
        end
        cur = cur:parent()
      end
      if current_index then break end
    end
  end

  return list, current_index
end

local function resolve_sibling(node, bufnr, relation)
  local list, current_index = get_siblings_and_index(node, bufnr)
  if #list == 0 then return nil end
  if relation == "first_sibling" then
    if current_index == 1 then return nil end
    return list[1]
  end
  if relation == "last_sibling" then
    if current_index == #list then return nil end
    return list[#list]
  end
  if not current_index then return nil end
  if relation == "next_sibling" then return list[current_index + 1] end
  if relation == "prev_sibling" then return current_index > 1 and list[current_index - 1] or nil end
  return nil
end

local relation_resolvers = {
  parent        = function(n, b) return jump_targets.resolve_next_highest_anchor({ bufnr = b, node = n }) end,
  prev_sibling  = function(n, b) return resolve_sibling(n, b, "prev_sibling") end,
  next_sibling  = function(n, b) return resolve_sibling(n, b, "next_sibling") end,
  first_sibling = function(n, b) return resolve_sibling(n, b, "first_sibling") end,
  last_sibling  = function(n, b) return resolve_sibling(n, b, "last_sibling") end,
  child         = function(n, b)
    local cfg = treesitter_config.get()
    local resolve_options = anchor_actionable.resolve_options_from_config(cfg)
    local function find_first(node)
      for i = 0, node:named_child_count() - 1 do
        local child = node:named_child(i)
        local ni = build_node_info({ bufnr = b, node = child })
        if ni and anchor_actionable.check(ni, resolve_options) then return child end
        local res = find_first(child)
        if res then return res end
      end
      return nil
    end
    return find_first(n)
  end,
}

function jump_targets.get_siblings_for_node(node_info)
  if not node_info or not node_info.node then return {} end
  local sibs, _ = get_siblings_and_index(node_info.node, node_info.bufnr)
  return sibs
end

function jump_targets.resolve(selected_node_info, relation)
  if not selected_node_info or not selected_node_info.node then return nil end
  local resolver = relation_resolvers[relation]
  if not resolver then return nil end
  local target = resolver(selected_node_info.node, selected_node_info.bufnr)
  if not target then return nil end
  target = salvage_target.focus_node(target, selected_node_info.bufnr, nil)
  return build_node_info({ bufnr = selected_node_info.bufnr, node = target })
end

function jump_targets.resolve_next_highest_anchor(selected_node_info)
  if not selected_node_info or not selected_node_info.node then return nil end
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
        return build_node_info({ bufnr = selected_node_info.bufnr, node = focused })
      end
    end
    cur = cur:parent()
  end
  return nil
end

function jump_targets.is_document_root(node_info)
  local node = node_info and node_info.node
  return node and node:parent() == nil
end

function jump_targets.jump_action(target_node_info)
  return function()
    if not target_node_info then return end
    local row = (target_node_info.start_row or 0) + 1
    local col = (target_node_info.start_col or 0)
    pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
  end
end

return jump_targets
