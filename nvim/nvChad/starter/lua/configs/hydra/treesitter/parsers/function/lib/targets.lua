local metrics = require("configs.hydra.treesitter.parsers.function.lib.metrics")
local parameters = require("configs.hydra.treesitter.parsers.function.lib.parameters")

local M = {}

-- Read text from a Treesitter node safely.
local function get_node_text(node, bufnr)
  local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
  if not ok then
    return ""
  end

  return text or ""
end

-- Build a jump target from a node position.
local function to_target(node, bufnr, label)
  local row, col = node:start()
  return {
    bufnr = bufnr,
    row = row,
    col = col,
    label = label,
  }
end

-- Extract a human-readable function name from the function node.
function M.extract_function_name(function_node, bufnr)
  local params = parameters.find_parameter_container(function_node)
  local child_count = function_node:named_child_count()
  local fallback = ""

  for i = 0, child_count - 1 do
    local child = function_node:named_child(i)
    if params and child:id() == params:id() then
      break
    end

    local text = vim.trim(get_node_text(child, bufnr))
    if text ~= "" then
      if fallback == "" then
        fallback = text
      end

      if child:type() == "identifier" then
        return text
      end
    end
  end

  return fallback
end

-- Build jump targets for the parameter container and each parameter.
function M.build_parameter_targets(node_info)
  local parameter_nodes, parameter_container = parameters.list_parameters(node_info.node)
  local targets = {
    container = nil,
    parameters = {},
  }

  if parameter_container then
    targets.container = to_target(parameter_container, node_info.bufnr, "parameters")
  end

  for index, node in ipairs(parameter_nodes or {}) do
    targets.parameters[index] = to_target(node, node_info.bufnr, "parameter " .. tostring(index))
  end

  return targets
end

-- Build jump targets for nested functions.
function M.build_nested_function_targets(node_info)
  local targets = {}
  for _, node in ipairs(metrics.find_nested_functions(node_info.node)) do
    local name = M.extract_function_name(node, node_info.bufnr)
    if name == "" then
      name = "nested function"
    end

    targets[#targets + 1] = to_target(node, node_info.bufnr, name)
  end

  return targets
end

-- Build jump targets for assignment-like nodes.
function M.build_assignment_targets(node_info)
  local targets = {}
  local all_assignments = {}

  vim.list_extend(all_assignments, metrics.find_assignments(node_info.node))
  vim.list_extend(all_assignments, metrics.find_table_assignments(node_info.node))

  for index, node in ipairs(all_assignments) do
    targets[index] = to_target(node, node_info.bufnr, "assignment " .. tostring(index))
  end

  return targets
end

return M

