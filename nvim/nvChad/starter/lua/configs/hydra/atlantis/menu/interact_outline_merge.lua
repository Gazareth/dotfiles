local column_titles = require("configs.hydra.atlantis.menu.column_titles")
local layout = require("configs.hydra.atlantis.schema.actions.layout")

local M = {}

function M.build_interact_section(interact_raw, outline_items, parsed_anchor)
  if type(interact_raw) ~= "table" or interact_raw.__abort_open == true then
    return interact_raw
  end

  local title = column_titles.interact()
  local items

  if type(outline_items) ~= "table" or #outline_items == 0 then
    items = interact_raw.items
  else
    items = vim.deepcopy(interact_raw.items) or {}
    local kind = parsed_anchor and parsed_anchor.node_kind
    local specific_title = layout.specific_title_for_anchor_kind(kind)

    local has_anchor_specific_heading = false
    for _, it in ipairs(items) do
      if type(it) == "table" and type(it.heading) == "string" and it.heading ~= layout.action_common_heading then
        has_anchor_specific_heading = true
        break
      end
    end

    if not has_anchor_specific_heading then
      items[#items + 1] = { heading = specific_title }
      items[#items + 1] = { separator = true }
    end
    for _, it in ipairs(outline_items) do
      items[#items + 1] = it
    end
  end

  return {
    title = title,
    items = items,
  }
end

return M
