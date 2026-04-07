local util = require("configs.hydra.hint.util")

local M = {}

function M.render_item(item)
  if item.separator then
    if type(item.label) == "string" and item.label ~= "" then
      return "--- " .. item.label .. " ---"
    end
    return ""
  end

  if type(item.heading) == "string" and item.heading ~= "" then
    return "== " .. item.heading .. " =="
  end

  if type(item._resolved_key) == "string" and item._resolved_key ~= "" then
    local icon = item.icon or ""
    local label = item.label or ""
    return string.format("[%s] %s %s", item._resolved_key, icon, label)
  end

  return item.label or ""
end

function M.section_lines(section)
  local title = util.escape_hint_text(section.title or "")
  local lines = {}

  if title ~= "" then
    lines[#lines + 1] = title
    lines[#lines + 1] = string.rep("-", math.max(20, util.str_width(title)))
    lines[#lines + 1] = ""
  else
    lines[#lines + 1] = ""
  end

  local first_item = true
  for _, item in ipairs(section.items or {}) do
    local rendered = util.escape_hint_text(M.render_item(item))
    -- Add padding before subheadings and labeled separators, but not for first item
    if not first_item and ((type(item.heading) == "string" and item.heading ~= "") or
       (item.separator and type(item.label) == "string" and item.label ~= "")) then
      lines[#lines + 1] = ""
    end
    if rendered ~= "" then
      lines[#lines + 1] = rendered
      first_item = false
    end
  end

  return lines
end

return M
