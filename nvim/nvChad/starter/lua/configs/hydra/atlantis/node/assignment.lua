local action_ids = require("configs.hydra.atlantis.treesitter.lib.atlantis.constants").action_ids
local title_builder = require("configs.hydra.atlantis.node.title")
local node_actions = require("configs.hydra.atlantis.node_actions.config")
local common_actions = require("configs.hydra.atlantis.node.common_actions")
local supported_nodes = require("configs.hydra.atlantis.treesitter.lib.constants").supported_nodes

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
  local targets = type(parsed) == "table" and parsed.targets or {}
  local items = {
    {
      heading = "Targets",
    },
    {
      separator = true,
    },
  }

  if type(targets.left) == "table" then
    items[#items + 1] = {
      key = "h",
      icon = ">",
      label = "Left hand side: " .. tostring(targets.left.name or targets.left.label or "left hand side"),
      action_id = action_ids.jump,
      action = node_actions.build(supported_nodes.assignment, "jump_to_lhs", {
        node_info = node_info,
        parsed = parsed,
        target = targets.left,
      }),
    }
  end

  if type(targets.right) == "table" then
    items[#items + 1] = {
      key = "l",
      icon = ">",
      label = "Right hand side: " .. tostring(targets.right.name or targets.right.label or "right hand side"),
      action_id = action_ids.jump,
      action = node_actions.build(supported_nodes.assignment, "jump_to_rhs", {
        node_info = node_info,
        parsed = parsed,
        target = targets.right,
      }),
    }
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