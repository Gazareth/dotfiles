local util = require("configs.hydra.hint.util")
local keys = require("configs.hydra.hint.keys")
local render = require("configs.hydra.hint.render")
local title = require("configs.hydra.hint.title")

local M = {}

-- Build hint text layout
function M.build(sections, opts)
  opts = opts or {}
  local normalized = keys.normalize_sections(sections)
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

  local output = {}
  for row = 1, max_rows do
    local c1 = util.pad_right(col_lines[1][row] or "", widths[1])
    local c2 = util.pad_right(col_lines[2][row] or "", widths[2])
    local c3 = util.pad_right(col_lines[3][row] or "", widths[3])
    output[#output + 1] = c1 .. " | " .. c2 .. " | " .. c3
  end

  -- Header above section columns
  local total_width = widths[1] + widths[2] + widths[3] + 6
  local title_lines = title.build_title_lines(opts.title, total_width)
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

  return {
    sections = normalized,
    hint = table.concat(output, "\n"),
  }
end

return M
