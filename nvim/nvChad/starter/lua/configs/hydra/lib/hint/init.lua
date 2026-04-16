local util = require("configs.hydra.lib.hint.util")
local keys = require("configs.hydra.lib.hint.keys")
local render = require("configs.hydra.lib.hint.render")
local title = require("configs.hydra.lib.hint.title")

local M = {}

-- One line with left text at start and right text at end (Hydra-safe escaped strings)
local function build_footer_line(left, right, width)
  local lw = util.str_width(left)
  local rw = util.str_width(right)
  local gap = width - lw - rw
  if gap > 0 then
    return left .. string.rep(" ", gap) .. right
  end
  if gap == 0 then
    return left .. right
  end
  return left .. " " .. right
end

-- Build hint text layout
function M.build(sections, opts)
  opts = opts or {}
  local normalized = keys.normalize_sections(sections, opts)
  local col_lines = {
    render.section_lines(normalized[1]),
    render.section_lines(normalized[2]),
    render.section_lines(normalized[3]),
  }

  local widths = { 0, 0, 0 }
  local max_rows = 0

  for column = 1, 3 do
    for _, line in ipairs(col_lines[column]) do
      widths[column] = math.max(widths[column], util.str_width(line))
    end
    max_rows = math.max(max_rows, #col_lines[column])
  end

  -- Omit empty columns so single-section menus (e.g. file nav) do not show trailing ` | | `.
  local active = {}
  for column = 1, 3 do
    if widths[column] > 0 then
      active[#active + 1] = column
    end
  end
  if #active == 0 then
    active = { 1 }
  end

  local output = {}
  for row = 1, max_rows do
    local parts = {}
    for i = 1, #active do
      local column = active[i]
      parts[#parts + 1] = util.pad_right(col_lines[column][row] or "", widths[column])
    end
    output[#output + 1] = table.concat(parts, " | ")
  end

  local total_width = 0
  for i = 1, #active do
    total_width = total_width + widths[active[i]]
  end
  if #active > 1 then
    total_width = total_width + 3 * (#active - 1)
  end

  -- Horizontal inset for section rows only (not title or footer).
  local pl = math.max(0, math.floor(tonumber(opts.padding_left) or 0))
  local pr = math.max(0, math.floor(tonumber(opts.padding_right) or 0))
  if pl > 0 or pr > 0 then
    local lhs = string.rep(" ", pl)
    local rhs = string.rep(" ", pr)
    for i = 1, #output do
      output[i] = lhs .. output[i] .. rhs
    end
  end

  local inner_max_w = 0
  for _, line in ipairs(output) do
    inner_max_w = math.max(inner_max_w, util.str_width(line))
  end
  if inner_max_w == 0 then
    inner_max_w = total_width
  end
  local width_for_title = math.max(total_width, inner_max_w)

  -- Header above section columns (full width; not padded horizontally)
  local title_lines = title.build_title_lines(opts.title, width_for_title, opts)
  if #title_lines > 0 then
    local with_header = {}
    for _, line in ipairs(title_lines) do
      with_header[#with_header + 1] = line
    end
    for _, line in ipairs(output) do
      with_header[#with_header + 1] = line
    end
    output = with_header
  end

  local footer = type(opts.footer) == "table" and opts.footer or nil
  if footer then
    local left = util.escape_hint_text(type(footer.left) == "string" and footer.left or "")
    local right = util.escape_hint_text(type(footer.right) == "string" and footer.right or "")
    local footer_width = width_for_title
    for _, line in ipairs(output) do
      footer_width = math.max(footer_width, util.str_width(line))
    end
    output[#output + 1] = string.rep("-", footer_width)
    output[#output + 1] = build_footer_line(left, right, footer_width)
  end

  return {
    sections = normalized,
    hint = table.concat(output, "\n"),
  }
end

return M
