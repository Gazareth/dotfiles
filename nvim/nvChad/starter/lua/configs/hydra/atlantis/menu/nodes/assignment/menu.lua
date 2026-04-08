local title_builder = require("configs.hydra.atlantis.menu.nodes.common.title")
local target_builder = require("configs.hydra.atlantis.menu.nodes.assignment.target")
local value_builder = require("configs.hydra.atlantis.menu.nodes.assignment.value")
local common_actions = require("configs.hydra.atlantis.menu.actions.common")
local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes

local M = {}

-- Assignment title parts
local function build_title(parsed)
  local metrics = {}
  local parsed_metrics = type(parsed) == "table" and parsed.metrics or nil

  if type(parsed_metrics) == "table" then
    if parsed_metrics.is_local then
      metrics[#metrics + 1] = "local"
    end

    if parsed_metrics.line_span and parsed_metrics.line_span > 1 then
      metrics[#metrics + 1] = tostring(parsed_metrics.line_span) .. " lines"
    end
  end

  return title_builder.build({
    semantic_kind = "assignment",
    node_type = parsed and parsed.node_type,
    name = title_builder.extract_assignment_name(parsed and parsed.text),
    metrics = metrics,
  })
end

-- Assignment menu rows
function M.build(node_info, parsed)
  local items = {
    {
      heading = "Targets",
    },
    {
      separator = true,
    },
  }

  local lhs_row = target_builder.build_row(node_info, parsed, "h")
  if type(lhs_row) == "table" then
    items[#items + 1] = lhs_row
  end

  local rhs_row = value_builder.build_row(node_info, parsed, "l")
  if type(rhs_row) == "table" then
    items[#items + 1] = rhs_row
  end

  items[#items + 1] = {
    separator = true,
  }
  -- Shared generic action rows
  local generic_rows = common_actions.build_generic_action_rows(supported_nodes.assignment, "assignment", {
    node_info = node_info,
    parsed = parsed,
  })

  for _, row in ipairs(generic_rows) do
    items[#items + 1] = row
  end

  return {
    title = build_title(parsed),
    items = items,
  }
end

return M