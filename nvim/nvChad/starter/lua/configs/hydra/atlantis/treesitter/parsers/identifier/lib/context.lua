local treesitter_constants = require("configs.hydra.atlantis.treesitter.lib.constants")
local roles = treesitter_constants.roles
local function_constants = require("configs.hydra.atlantis.treesitter.parsers.function.lib.constants")
local function_lib = require("configs.hydra.atlantis.treesitter.parsers.function.lib")
local parse_function = require("configs.hydra.atlantis.treesitter.parsers.function").parse_function
local build_node_info = require("configs.hydra.atlantis.treesitter.lib").build_node_info

local M = {}

-- Descendant check
local function is_descendant_of(node, ancestor)
  local current = node
  while current do
    if current:id() == ancestor:id() then
      return true
    end

    current = current:parent()
  end

  return false
end

-- Function-name identifier check
local function is_function_name_identifier(node, function_ancestor)
  local params = function_lib.find_parameter_container(function_ancestor)
  local child_count = function_ancestor:named_child_count()

  for i = 0, child_count - 1 do
    local child = function_ancestor:named_child(i)
    if params and child:id() == params:id() then
      break
    end

    if is_descendant_of(node, child) then
      return true
    end
  end

  return false
end

-- Enclosing function lookup
local function find_function_context_ancestor(node)
  local current = node and node:parent() or nil
  while current do
    if function_constants.function_like_types[current:type()]
      and is_function_name_identifier(node, current) then
      return current
    end

    current = current:parent()
  end

  return nil
end

-- Function-name parse reuse
local function build_function_identifier_result(function_node_info, parsed_function)
  local function_role = parsed_function.role or roles["function"]
  parsed_function.node_type = function_node_info.node_type
  parsed_function.text = function_node_info.text
  -- Semantic mapping source node
  parsed_function.semantic_node_info = function_node_info
  parsed_function.role = function_role .. " " .. roles.identifier
  parsed_function.display_name = parsed_function.role
  return parsed_function
end

-- Function-name context parse
function M.try_parse_identifier_function_context(node_info)
  local function_ancestor = find_function_context_ancestor(node_info.node)
  if not function_ancestor then
    return nil
  end

  local function_node_info = build_node_info({
    bufnr = node_info.bufnr,
    node = function_ancestor,
  })

  if not function_node_info then
    return nil
  end

  local ok, parsed = pcall(parse_function, function_node_info)
  if not ok or type(parsed) ~= "table" then
    return nil
  end

  return build_function_identifier_result(function_node_info, parsed)
end

return M
