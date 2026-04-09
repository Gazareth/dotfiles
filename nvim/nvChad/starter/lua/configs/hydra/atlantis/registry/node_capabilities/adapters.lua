-- Build adapter instances for node kinds that expose richer behavior
local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes
local parameter_sibling = require("configs.hydra.atlantis.ops.node_kinds.function.parameter.sibling")

local M = {}

-- Adapter factories keyed by node kind
local adapter_specs = {
  [supported_nodes.parameter] = function(runtime_ctx)
    return parameter_sibling.create(runtime_ctx)
  end,
}

-- Build node adapter instance from adapter spec table
function M.build(node_kind, runtime_ctx)
  local spec = adapter_specs[node_kind]
  if type(spec) ~= "function" then
    return nil
  end

  local ok, adapter = pcall(spec, runtime_ctx or {})
  if not ok or type(adapter) ~= "table" then
    return nil
  end

  return adapter
end

return M
