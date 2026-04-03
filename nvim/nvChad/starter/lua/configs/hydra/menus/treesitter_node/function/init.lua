local actions = require("configs.hydra.menus.treesitter_node.function.lib.actions")
local navigation = require("configs.hydra.menus.treesitter_node.function.lib.navigation")
local parsed_helpers = require("configs.hydra.menus.treesitter_node.function.lib.parsed")

local M = {}

-- Build a structured function menu with grouped metric headings and jump targets.
function M.build(node_info, parsed)
  local _ = node_info
  local metrics = parsed_helpers.get_metrics(parsed)
  local targets = parsed_helpers.get_targets(parsed)
  local parameter_count = parsed_helpers.value_or(metrics, "parameter_count", 0)
  local nested_count = parsed_helpers.value_or(metrics, "nested_function_count", 0)
  local assignment_count = #(targets.assignments or {})
  local line_span = parsed_helpers.value_or(metrics, "line_span", "?")
  local called_count = parsed_helpers.value_or(metrics, "called_count", 0)
  local hotkeys = navigation.build_hotkey_pool()
  local used = { c = true, h = true }
  local cursor = 1

  local items = {
    {
      key = "c",
      icon = ">",
      label = "Change name",
      action = actions.build_change_name_action(),
    },
    {
      key = "h",
      icon = ">",
      label = "View call hierarchy",
      action = actions.build_call_hierarchy_action(),
    },
    {
      separator = true,
      label = "󰆧 Parameters: " .. tostring(parameter_count),
    },
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
