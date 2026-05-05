local lib = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.node_kinds.identifier.lib")
local parse_parameter = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.node_kinds.parameter").parse_parameter
local roles = require("configs.hydra.atlantis-deprecated.prepare.anchor_point.probe.treesitter.constants").roles

local M = {}

-- Function-name check before role lookup
function M.parse_identifier(node_info)
  local function_context = lib.try_parse_identifier_function_context(node_info)
  if function_context then
    return function_context
  end

  local role = lib.classify_identifier_role(node_info)
  if role == roles.parameter then
    return parse_parameter(node_info)
  end

  return lib.build_identifier_result(node_info, role)
end

return M
