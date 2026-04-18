local hint_util = require("configs.hydra.lib.hint.util")
local hint_row_kinds = require("configs.hydra.lib.hint.row_kinds")

local hint_render = {}

function hint_render.render_item(item)
  return hint_row_kinds.render(item)
end

local function append_column_title_block(lines, section)
  local title = hint_util.escape_hint_text(section.title or "")
  if title ~= "" then
    lines[#lines + 1] = title
    lines[#lines + 1] = string.rep("-", math.max(20, hint_util.str_width(title)))
    lines[#lines + 1] = ""
  else
    lines[#lines + 1] = ""
  end
end

local function needs_spacer_before_item(item, first_item)
  if first_item then
    return false
  end
  return (type(item.heading) == "string" and item.heading ~= "")
    or (item.separator and type(item.label) == "string" and item.label ~= "")
end

function hint_render.section_lines(section)
  local lines = {}
  append_column_title_block(lines, section)

  local first_item = true
  for _, item in ipairs(section.items or {}) do
    if needs_spacer_before_item(item, first_item) then
      lines[#lines + 1] = ""
    end
    local rendered = hint_util.escape_hint_text(hint_render.render_item(item))
    if rendered ~= "" then
      lines[#lines + 1] = rendered
      first_item = false
    end
  end

  return lines
end

return hint_render
