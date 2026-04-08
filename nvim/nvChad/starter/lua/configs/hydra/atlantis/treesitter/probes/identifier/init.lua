local lib = require("configs.hydra.atlantis.treesitter.probes.identifier.lib")

local M = {}

-- Function-name check before role lookup
function M.parse_identifier(node_info)
  local function_context = lib.try_parse_identifier_function_context(node_info)
  if function_context then
    return function_context
  end

  return lib.build_identifier_result(node_info, lib.classify_identifier_role(node_info))
end

return M
