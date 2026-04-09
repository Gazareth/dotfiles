-- Build submenu specs by node kind for menu rendering from pre-resolved capability data
local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes
local navigate = require("configs.hydra.atlantis.ops.function.navigate")

local M = {}

-- Build declarative submenu specs for function anchors
local function build_function_submenu_specs(runtime_ctx)
  local parsed = type(runtime_ctx) == "table" and runtime_ctx.parsed or nil
  local targets = type(parsed) == "table" and type(parsed.targets) == "table" and parsed.targets or {}
  local parameter_targets = type(targets.parameters) == "table" and targets.parameters or {}
  local nested_function_targets = type(targets.nested_functions) == "table" and targets.nested_functions or {}
  local assignment_targets = type(targets.assignments) == "table" and targets.assignments or {}

  return {
    {
      id = "parameters",
      order = 10,
      key = "p",
      icon = ">",
      label = "Parameters...",
      is_available = function()
        return type(targets.parameter_container) == "table"
      end,
      open = function()
        local parameter_anchor = parameter_targets[1] or targets.parameter_container
        if type(parameter_anchor) == "table" then
          navigate.navigate_and_open_at_depth(parameter_anchor, "lowest_node")()
        end
      end,
    },
    {
      id = "body",
      order = 20,
      key = "b",
      icon = ">",
      label = "Body...",
      is_available = function()
        return #nested_function_targets > 0 or #assignment_targets > 0
      end,
      open = function()
        local body_start = nested_function_targets[1] or assignment_targets[1]
        if type(body_start) == "table" then
          navigate.navigate_and_open_at_depth(body_start, "depth_1")()
        end
      end,
    },
  }
end

-- Submenu spec builders keyed by node kind
local submenu_specs = {
  [supported_nodes.fn] = function(_, runtime_ctx)
    return build_function_submenu_specs(runtime_ctx)
  end,
}

-- Build submenu specs from node-kind-specific builder
function M.build(node_kind, runtime_ctx, adapter)
  local submenu_builder = submenu_specs[node_kind]
  if type(submenu_builder) ~= "function" then
    return nil
  end

  return submenu_builder(adapter, runtime_ctx)
end

return M
