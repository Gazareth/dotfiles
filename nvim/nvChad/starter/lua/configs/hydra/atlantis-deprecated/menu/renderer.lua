local action_column_items = require("configs.hydra.atlantis-deprecated.menu.action_column_items")

local action_column_renderer = {}

function action_column_renderer.build_from_context(runtime_ctx)
  if type(runtime_ctx) ~= "table" or not runtime_ctx.cursor_node_info then
    return {
      __abort_open = true,
      __abort_message = "Atlantis menu unavailable: no Treesitter node at cursor.",
    }
  end

  local render_spec = runtime_ctx.render_spec
  if type(render_spec) ~= "table" then
    return {
      __abort_open = true,
      __abort_message = "Atlantis menu unavailable: render spec missing.",
    }
  end

  return {
    title = render_spec.title,
    items = action_column_items.from_render_spec(render_spec),
  }
end

return action_column_renderer
