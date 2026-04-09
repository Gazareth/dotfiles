local action_rows = require("configs.hydra.atlantis.menu.actions.rows")
local navigation = require("configs.hydra.atlantis.menu.nodes.function.lib.navigation")
local navigate = require("configs.hydra.atlantis.menu.nodes.function.lib.navigate")
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

  -- Submenu navigation items
  items[#items + 1] = { separator = true }
  
  if targets.parameter_container then
    -- Open parameters from first parameter when available
    local parameter_anchor = (targets.parameters and targets.parameters[1]) or targets.parameter_container
    items[#items + 1] = {
      key = "p",
      icon = "󰆧",
      label = "Parameters...",
      action = navigate.navigate_and_open_at_depth(parameter_anchor, "depth_1"),
    }
  end

  if #(targets.nested_functions or {}) > 0 or #(targets.assignments or {}) > 0 then
    items[#items + 1] = {
      key = "b",
      icon = "󰅲",
      label = "Body...",
      action = function()
        -- Navigate to first body item (nested function or assignment)
        local body_start = targets.nested_functions and targets.nested_functions[1]
        if not body_start and targets.assignments then
          body_start = targets.assignments[1]
        end
        if body_start then
          navigate.navigate_and_open_at_depth(body_start, "depth_1")()
        end
      end,
    }
  end

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
