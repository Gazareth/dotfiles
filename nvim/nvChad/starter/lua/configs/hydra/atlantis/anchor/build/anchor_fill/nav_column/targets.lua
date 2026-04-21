local anchor_actionable = require("configs.hydra.atlantis.anchor.build.find_from_node.actionable")
local build_node_info = require("configs.hydra.atlantis.anchor.probe.treesitter.node_info").build_node_info
local salvage_target = require("configs.hydra.atlantis.anchor.build.anchor_fill.nav_column.salvage_target")
local treesitter_config = require("configs.hydra.atlantis.anchor.probe.treesitter.config")

local jump_targets = {}

function jump_targets.resolve(selected_node_info, relation)
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
