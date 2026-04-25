local targets = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.targets")
local row_labels = require("configs.hydra.atlantis.prepare.anchor_point.build.anchor_fill.nav_column.row_labels")

local context_rows = {}

function context_rows.append_stack_neighbors(items, candidates, selected_index, jump_labels, menu_opts)
  if type(selected_index) ~= "number" then
    return
  end

  if selected_index >= #(candidates or {}) then
    return
  end

  local depth = type(menu_opts) == "table" and (menu_opts.depth or 0) or 0
  local higher_spec = row_labels.spec("higher")
  local row_spec = higher_spec
  local default_key = "w"
  local default_icon = "⬆"
  local neighbor_ni = candidates[selected_index + 1] and candidates[selected_index + 1].node_info
  local neighbor_reopen = { depth = depth }
  if type(neighbor_ni) == "table" and neighbor_ni.node then
    neighbor_reopen.anchor_pos = { bufnr = neighbor_ni.bufnr or 0, row = (neighbor_ni.start_row or 0) + 1, col = neighbor_ni.start_col or 0 }
  end
  items[#items + 1] = {
    key = row_spec and row_spec.key or default_key,
    icon = row_spec and row_spec.icon or default_icon,
    label = row_labels.with_quoted(
      row_labels.nav_context_higher_in_chain(),
      row_labels.neighbor(selected_index + 1, candidates[selected_index + 1], jump_labels)
    ),
    action = targets.jump_action(neighbor_ni),
    reopen = neighbor_reopen,
  }
end

return context_rows
