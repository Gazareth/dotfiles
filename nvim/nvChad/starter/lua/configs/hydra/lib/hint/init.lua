local hint_util = require("configs.hydra.lib.hint.util")
local hint_keys = require("configs.hydra.lib.hint.keys")
local hint_render = require("configs.hydra.lib.hint.render")
local hint_title = require("configs.hydra.lib.hint.title")

local hydra_hint = {}

-- One line with left text at start and right text at end (Hydra-safe escaped strings)
local function build_footer_line(left, right, width)
  local lw = hint_util.str_width(left)
  local rw = hint_util.str_width(right)
  local gap = width - lw - rw
  if gap > 0 then
    return left .. string.rep(" ", gap) .. right
  end
  if gap == 0 then
    return left .. right
  end
  return left .. " " .. right
end

--- Each Hydra `section` spec ({ title, items }) maps to one visual column in the hint grid (` | ` separated).
local function column_metrics(normalized_sections)
  local col_lines = {
    hint_render.section_lines(normalized_sections[1]),
    hint_render.section_lines(normalized_sections[2]),
    hint_render.section_lines(normalized_sections[3]),
  }
  local widths = { 0, 0, 0 }
  local max_rows = 0
  for column = 1, 3 do
    for _, line in ipairs(col_lines[column]) do
      widths[column] = math.max(widths[column], hint_util.str_width(line))
    end
    max_rows = math.max(max_rows, #col_lines[column])
  end
  local active = {}
  for column = 1, 3 do
    if widths[column] > 0 then
      active[#active + 1] = column
    end
  end
  if #active == 0 then
    active = { 1 }
  end
  return col_lines, widths, max_rows, active
end

local function merge_columns_to_rows(col_lines, widths, active, max_rows)
  local output = {}
  for row = 1, max_rows do
    local parts = {}
    for i = 1, #active do
      local column = active[i]
      parts[#parts + 1] = hint_util.pad_right(col_lines[column][row] or "", widths[column])
    end
    output[#output + 1] = table.concat(parts, " | ")
  end
  return output
end

--- Build floating hint text: three section specs become up to three columns, padded and joined.
function hydra_hint.build(sections, opts)
  opts = opts or {}
  local normalized = hint_keys.normalize_sections(sections, opts)
  local col_lines, widths, max_rows, active = column_metrics(normalized)
  local output = merge_columns_to_rows(col_lines, widths, active, max_rows)

  local total_width = 0
  for i = 1, #active do
    total_width = total_width + widths[active[i]]
  end
  if #active > 1 then
    total_width = total_width + 3 * (#active - 1)
  end

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
    inner_max_w = math.max(inner_max_w, hint_util.str_width(line))
  end
  if inner_max_w == 0 then
    inner_max_w = total_width
  end
  local width_for_title = math.max(total_width, inner_max_w)

  local title_lines = hint_title.build_title_lines(opts.title, width_for_title, opts)
  local common_actions = opts.common_actions
  local header_lines = {}

  if #title_lines > 0 then
    for _, line in ipairs(title_lines) do
      header_lines[#header_lines + 1] = line
    end
  end

  if common_actions and #common_actions > 0 then
    local action_parts = {}
    for _, item in ipairs(common_actions) do
      table.insert(action_parts, string.format("[%s] %s", item.key, item.label))
    end
    local action_line = table.concat(action_parts, " - ")
    local safe_action_line = hint_util.escape_hint_text(action_line)
    local aw = hint_util.str_width(safe_action_line)

    -- Ensure we use at least width_for_title
    local current_max_w = width_for_title
    for _, line in ipairs(header_lines) do
      current_max_w = math.max(current_max_w, hint_util.str_width(line))
    end
    current_max_w = math.max(current_max_w, aw)

    local left = math.max(0, math.floor((current_max_w - aw) / 2))
    header_lines[#header_lines + 1] = string.rep(" ", left) .. safe_action_line
    header_lines[#header_lines + 1] = string.rep("=", current_max_w)
  end

  if #header_lines > 0 then
    local with_header = {}
    for _, line in ipairs(header_lines) do
      with_header[#with_header + 1] = line
    end
    for _, line in ipairs(output) do
      with_header[#with_header + 1] = line
    end
    output = with_header
  end

  local footer = type(opts.footer) == "table" and opts.footer or nil
  if footer then
    local left = hint_util.escape_hint_text(type(footer.left) == "string" and footer.left or "")
    local right = hint_util.escape_hint_text(type(footer.right) == "string" and footer.right or "")
    local footer_width = width_for_title
    for _, line in ipairs(output) do
      footer_width = math.max(footer_width, hint_util.str_width(line))
    end
    output[#output + 1] = string.rep("-", footer_width)
    output[#output + 1] = build_footer_line(left, right, footer_width)
  end

  return {
    sections = normalized,
    common_actions = common_actions,
    hint = table.concat(output, "\n"),
  }
end

return hydra_hint
