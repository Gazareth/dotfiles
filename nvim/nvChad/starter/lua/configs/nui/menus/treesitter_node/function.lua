local generic = require("configs.nui.menus.treesitter_node.generic")

local M = {}

-- Formats function metrics into a single line for display in the menu
local function create_metric_line(metrics)
  if type(metrics) ~= "table" then
    return ""
  end

  local parameters = metrics.parameter_count
  if parameters == nil then
    parameters = "?"
  end

  local span = metrics.line_span or "?"
  local nested = metrics.nested_function_count or 0
  local assignments = metrics.assignment_count or 0

  return "params=" .. tostring(parameters)
    .. " lines=" .. tostring(span)
    .. " nested=" .. tostring(nested)
    .. " assigns=" .. tostring(assignments)
end

-- Builds a menu spec for a function node, including its role and relevant metrics
function M.build(node_info, parsed)
  local spec = generic.build(node_info, parsed)
  local role = parsed.role or "function"

  spec.title = role
  spec.items = vim.list_extend({
    {
      heading = create_metric_line(parsed.metrics),
    },
  }, spec.items)

  return spec
end

return M
