-- Formats a pre-resolved render spec from runtime context into a menu item list; knows nothing about node semantics
local filter_allowed_items = require("configs.hydra.atlantis.menu.components.action.filter").filter_items

local M = {}

-- Assemble render spec into a hydra-ready menu spec with title and item list
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

  if #(render_spec.submenu_rows or {}) > 0 then
    items[#items + 1] = { separator = true }
    for _, row in ipairs(render_spec.submenu_rows) do
      items[#items + 1] = row
    end
  end

  items = filter_allowed_items(runtime_ctx.parsed_anchor, items, render_spec.action_ids)

  return {
    title = render_spec.title,
    items = items,
  }
end

return M
