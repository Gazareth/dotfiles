local layout = require("configs.hydra.atlantis.schema.actions.layout")

local M = {}

function M.build_from_context(runtime_ctx)
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

  local items = {
    { heading = layout.action_common_heading },
    { separator = true },
  }

  for _, row in ipairs(render_spec.common_primary_rows or {}) do
    items[#items + 1] = row
  end

  local overflow_rows = render_spec.common_overflow_rows or {}
  local overflow_names = type(render_spec.grouped_action_names) == "table"
      and render_spec.grouped_action_names.common_overflow
    or {}
  if #overflow_rows > 0 and #overflow_names > 0 then
    items[#items + 1] = {
      key = layout.action_overflow_menu_key or ".",
      icon = ">",
      label = layout.action_overflow_row_label,
      action = nil,
      _action_common_overflow = true,
      _overflow_action_names = overflow_names,
    }
  end

  local specific_rows = render_spec.specific_rows or {}
  local specific_title = render_spec.specific_section_title
  if #specific_rows > 0 and type(specific_title) == "string" and specific_title ~= "" then
    items[#items + 1] = { heading = specific_title }
    items[#items + 1] = { separator = true }
    for _, row in ipairs(specific_rows) do
      items[#items + 1] = row
    end
  end

  return {
    title = render_spec.title,
    items = items,
  }
end

return M
