local constants = require("configs.nui.treesitter.parsers.function.lib.constants")
local parameters = require("configs.nui.treesitter.parsers.function.lib.parameters")
local treesitter_constants = require("configs.nui.treesitter.lib.constants")
local node_types = treesitter_constants.node_types
local roles = treesitter_constants.roles

local M = {}

-- Walks the down the children in the tree starting from the given node, applying the given function to each node
local function walk(node, fn)
  if not node then
    return
  end

  fn(node)

  local child_count = node:named_child_count()
  for i = 0, child_count - 1 do
    walk(node:named_child(i), fn)
  end
end

function M.count_descendants(node, predicate)
  local count = 0
  walk(node, function(current)
    if current ~= node and predicate(current) then
      count = count + 1
    end
  end)
  return count
end

function M.detect_method_kind(node_info)
  if node_info.node_type == node_types.method_definition then
    return roles.method
  end

  if type(node_info.parent_type) == "string" and string.find(node_info.parent_type, roles.method, 1, true) then
    return roles.method
  end

  local params = parameters.find_parameter_container(node_info.node)
  if params and params:named_child_count() > 0 then
    local first = params:named_child(0)
    if first then
      local ok, first_text = pcall(vim.treesitter.get_node_text, first, node_info.bufnr)
      if ok and (first_text == "self" or first_text == "this") then
        return roles.method
      end
    end
  end

  return roles["function"]
end

M.constants = constants
M.function_like_types = constants.function_like_types
M.assignment_types = constants.assignment_types
M.table_assignment_types = constants.table_assignment_types
M.find_parameter_container = parameters.find_parameter_container
M.count_parameters = parameters.count_parameters

return M