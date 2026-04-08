local action_rows = require("configs.hydra.atlantis.menu.actions.rows")
local navigation = require("configs.hydra.atlantis.menu.nodes.function.lib.navigation")
local parsed_helpers = require("configs.hydra.atlantis.menu.nodes.function.lib.parsed")
local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes

local M = {}

-- Menu for parsed function nodes
function M.build(node_info, parsed)
  local metrics = parsed_helpers.get_metrics(parsed)
  local targets = parsed_helpers.get_targets(parsed)
  local parameter_count = parsed_helpers.value_or(metrics, "parameter_count", 0)
  local nested_count = parsed_helpers.value_or(metrics, "nested_function_count", 0)
  local assignment_count = #(targets.assignments or {})
  local line_span = parsed_helpers.value_or(metrics, "line_span", "?")
  local called_count = parsed_helpers.value_or(metrics, "called_count", 0)
  local hotkeys = navigation.build_hotkey_pool()
  local used = {}
  local cursor = 1

  -- Row context payload
  local row_ctx = {
    node_info = node_info,
    parsed = parsed,
  }

  -- Primary function action rows
  local primary_rows = action_rows.build_rows(supported_nodes.fn, {
    "rename",
    "view_call_hierarchy",
  }, {
    ctx = row_ctx,
  })

  for _, row in ipairs(primary_rows) do
    if type(row.key) == "string" and row.key ~= "" then
      used[row.key] = true
    end
  end

  -- Function menu rows
  local items = {}
  for _, row in ipairs(primary_rows) do
    items[#items + 1] = row
  end
  items[#items + 1] = {
    separator = true,
    label = "󰆧 Parameters: " .. tostring(parameter_count),
  }

  cursor = navigation.append_parameter_rows(items, targets, hotkeys, used, cursor)

  items[#items + 1] = {
    separator = true,
    label = "󰅲 Nested Functions: " .. tostring(nested_count),
  }

  cursor = navigation.append_nested_function_rows(items, targets, hotkeys, used, cursor)

  items[#items + 1] = {
    separator = true,
    label = "󰌭 Assigns: " .. tostring(assignment_count),
  }

  cursor = navigation.append_assignment_rows(items, targets, hotkeys, used, cursor)

  -- Metrics summary at the end
  items[#items + 1] = { separator = true }
  items[#items + 1] = {
    separator = true,
    label = "󱓎 Lines: " .. tostring(line_span) .. ", Called: " .. tostring(called_count),
  }
  items[#items + 1] = { separator = true }

  return {
    title = parsed_helpers.build_title(parsed),
    items = items,
  }
end

return M
