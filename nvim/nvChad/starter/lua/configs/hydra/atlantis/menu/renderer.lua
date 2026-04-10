local M = {}

function M.build_from_context(runtime_ctx)
  if type(runtime_ctx) ~= "table" or not runtime_ctx.cursor_node_info then
    return {
      __abort_open = true,
      __abort_message = "Treewalker menu unavailable: no Treesitter node at cursor.",
    }
  end

  local render_spec = runtime_ctx.render_spec
  if type(render_spec) ~= "table" then
    return {
      __abort_open = true,
      __abort_message = "Treewalker menu unavailable: render spec missing.",
    }
  end

  local items = {
    { heading = "Actions" },
    { separator = true },
  }

  for _, row in ipairs(render_spec.action_rows or {}) do
    items[#items + 1] = row
  end

  return {
    title = render_spec.title,
    items = items,
  }
end

return M
