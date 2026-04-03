local parameters = require("configs.hydra.treesitter.parsers.function.lib.parameters")
local treesitter_constants = require("configs.hydra.treesitter.lib.constants")
local node_types = treesitter_constants.node_types
local roles = treesitter_constants.roles
local method_receiver_names = treesitter_constants.method_receiver_names

local M = {}

-- Treat nodes with an explicit method type as methods.
local function is_method_node_type(node_info)
  return node_info.node_type == node_types.method_definition
end

-- Treat nodes as methods when the parent node name says they are methods.
local function has_method_parent_hint(node_info)
  return type(node_info.parent_type) == "string"
    and string.find(node_info.parent_type, roles.method, 1, true) ~= nil
end

-- Treat a function as a method when its first parameter is self or this.
local function has_method_receiver_param(node_info)
  local params = parameters.find_parameter_container(node_info.node)
  if not params or params:named_child_count() == 0 then
    return false
  end

  local first = params:named_child(0)
  if not first then
    return false
  end

  local ok, first_text = pcall(vim.treesitter.get_node_text, first, node_info.bufnr)
  return ok and method_receiver_names[first_text] == true
end

-- Choose whether this node should be labeled as a method or a function.
function M.is_function_or_method(node_info)
  if is_method_node_type(node_info)
    or has_method_parent_hint(node_info)
    or has_method_receiver_param(node_info) then
    return roles.method
  end

  return roles["function"]
end

return M
