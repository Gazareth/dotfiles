-- Build adapter instances using table-only adapter registry specs
local adapter_registry = require("configs.hydra.atlantis.registry.node_capabilities.adapters")

local M = {}

-- Merge callback lookups with later tables overriding earlier entries
local function merge_callbacks(base, extra)
  local merged = {}

  if type(base) == "table" then
    for key, value in pairs(base) do
      if type(key) == "string" and type(value) == "function" then
        merged[key] = value
      end
    end
  end

  if type(extra) == "table" then
    for key, value in pairs(extra) do
      if type(key) == "string" and type(value) == "function" then
        merged[key] = value
      end
    end
  end

  return merged
end

-- Compose subadapter callback groups into capability payload
local function compose_capabilities(adapter, subadapter_modules)
  local actions = {}
  local availability = {}

  for _, module_name in ipairs(subadapter_modules or {}) do
    if type(module_name) == "string" and module_name ~= "" then
      local subadapter = require(module_name)
      local spec = type(subadapter) == "table" and type(subadapter.build) == "function" and subadapter.build(adapter) or nil

      if type(spec) == "table" then
        actions = merge_callbacks(actions, spec.actions)
        availability = merge_callbacks(availability, spec.availability)
      end
    end
  end

  return {
    actions = actions,
    availability = availability,
  }
end

-- Build node adapter instance from registry spec and compose capabilities
function M.build(node_kind, runtime_ctx)
  local spec = adapter_registry[node_kind]
  if type(spec) ~= "table" then
    return nil
  end

  local factory_module = type(spec.factory) == "string" and spec.factory or nil
  local factory = factory_module and require(factory_module) or nil
  local create = type(factory) == "table" and factory.create or nil
  if type(create) ~= "function" then
    return nil
  end

  local ok, adapter = pcall(create, runtime_ctx or {})
  if not ok or type(adapter) ~= "table" then
    return nil
  end

  local capabilities = compose_capabilities(adapter, spec.subadapters)
  adapter.capability_actions = capabilities.actions
  adapter.capability_availability = capabilities.availability

  return adapter
end

return M
