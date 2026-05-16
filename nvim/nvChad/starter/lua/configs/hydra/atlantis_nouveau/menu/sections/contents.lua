local M = {}

-- Classification-mode groups. Each maps an item.category (set by the Rust
-- surveyor) to a heading and an optional hotkey prefix. Items get sequential
-- two-key hotkeys "<prefix><n>" except "other", which uses bare numerics.
local GROUPS = {
  { id = "assignment",  prefix = "a", heading = "Assignments"          },
  { id = "conditional", prefix = "b", heading = "Condition statements" },
  { id = "loop",        prefix = "o", heading = "Loops"                },
  { id = "function",    prefix = "f", heading = "Functions"            },
  { id = "other",       prefix = "",  heading = "Other"                },
}

-- Focus types whose outline shows structural parts of a single construct.
local COMPONENTS_FOCUS = {
  ["function"] = true,
  assignment   = true,
  conditional  = true,
  call         = true,
}

-- Focus types whose outline lists peers of a single kind (e.g. parameters).
local PARAMETERS_FOCUS = {
  parameter_list = true,
}

-- Items count above which the section is replaced with a vim.ui.select picker.
local OVERFLOW_THRESHOLD = 9

local function jump_to_item(bufnr, item)
  local range = item.range
  vim.api.nvim_win_set_cursor(0, { range.start_row + 1, range.start_col })
  vim.cmd("normal! zz")
  vim.schedule(function()
    require("configs.hydra.atlantis_nouveau").open({
      bufnr            = bufnr,
      target_node_type = item.node_type,
      target_start_row = range.start_row,
      target_start_col = range.start_col,
    })
  end)
end

local function open_picker(bufnr, prompt, items)
  vim.ui.select(items, {
    prompt = prompt .. ":",
    format_item = function(item) return item.label end,
  }, function(choice)
    if choice then jump_to_item(bufnr, choice) end
  end)
end

local function focus_node_type(result)
  local node = result and result.node and result.node.node
  return node and node.type or nil
end

-- Builds the rows for one section: a heading row followed by either per-item
-- rows or a single <Select...> row when the section exceeds OVERFLOW_THRESHOLD.
-- prefix is the group letter (e.g. "a") or "" for unprefixed sections; the
-- overflow Select hotkey is the prefix letter, falling back to "0".
local function render_section(bufnr, heading_text, picker_prompt, prefix, items)
  local rows = { { heading = heading_text } }

  if #items > OVERFLOW_THRESHOLD then
    local select_key = (prefix ~= "" and prefix) or "0"
    rows[#rows + 1] = {
      key    = select_key,
      label  = string.format("<Select %s...>", picker_prompt),
      action = function() open_picker(bufnr, picker_prompt, items) end,
    }
    return rows
  end

  local counter = 0
  for _, item in ipairs(items) do
    local key
    if type(item.hint_key) == "string" and item.hint_key ~= "" then
      key = item.hint_key
    else
      counter = counter + 1
      key = prefix .. tostring(counter)
    end
    rows[#rows + 1] = {
      key    = key,
      label  = item.label,
      action = function() jump_to_item(bufnr, item) end,
    }
  end
  return rows
end

local function build_classification_rows(result)
  local buckets = {}
  for _, g in ipairs(GROUPS) do buckets[g.id] = {} end

  for _, item in ipairs(result.outline) do
    local cat = item.category or "other"
    if not buckets[cat] then cat = "other" end
    table.insert(buckets[cat], item)
  end

  local rows = {}
  for _, group in ipairs(GROUPS) do
    local group_items = buckets[group.id]
    if #group_items > 0 then
      local heading = group.prefix ~= ""
        and string.format("%s [%s]", group.heading, group.prefix)
        or group.heading
      local section_rows = render_section(result.bufnr, heading, group.heading, group.prefix, group_items)
      for _, row in ipairs(section_rows) do
        rows[#rows + 1] = row
      end
    end
  end
  return rows
end

local function build_components_rows(result)
  return render_section(result.bufnr, "Components", "Components", "", result.outline)
end

local function build_parameters_rows(result)
  return render_section(result.bufnr, "Parameters", "Parameters", "", result.outline)
end

function M.build(result)
  local items = result.outline
  if not items or #items == 0 then return nil end

  local focus = focus_node_type(result)
  local rows
  if focus and COMPONENTS_FOCUS[focus] then
    rows = build_components_rows(result)
  elseif focus and PARAMETERS_FOCUS[focus] then
    rows = build_parameters_rows(result)
  else
    rows = build_classification_rows(result)
  end

  -- For component/parameter focus the navigate "l" key also jumps to the first
  -- outline item, so annotate its label to make that visible.
  if focus and (COMPONENTS_FOCUS[focus] or PARAMETERS_FOCUS[focus]) then
    for _, row in ipairs(rows) do
      if type(row.key) == "string" and row.key ~= "" then
        row.label = (row.label or "") .. " (l)"
        break
      end
    end
  end

  return { title = "Contents", items = rows }
end

return M
