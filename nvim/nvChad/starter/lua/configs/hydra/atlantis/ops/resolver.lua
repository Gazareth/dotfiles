local M = {}

local action_scopes = { "specific", "common" }

-- Require module safely and return nil on load failure
local function load_module(module_path)
  if type(module_path) ~= "string" or module_path == "" then
    return nil
  end

  local ok, mod = pcall(require, module_path)
  if not ok then
    return nil
  end

  return mod
end

-- Resolve builder callback from action module exports
local function resolve_builder_from_module(mod)
  if type(mod) ~= "table" then
    return nil
  end

  local builder = mod.build
  if type(builder) == "function" then
    return builder
  end

  return nil
end

-- Normalize node kind into module suffix token
local function normalize_node_kind(node_kind)
  if type(node_kind) ~= "string" or node_kind == "" then
    return nil
  end

  local normalized = node_kind:gsub("[^%w_]", "_")
  if normalized == "" then
    return nil
  end

  return normalized
end

-- Resolve action builder from scope path and optional node-kind override file
local function resolve_from_scope(action_name, node_kind, scope)
  if type(action_name) ~= "string" or action_name == "" then
    return nil
  end

  local base_path = "configs.hydra.atlantis.ops.actions." .. scope .. "." .. action_name
  local node_suffix = normalize_node_kind(node_kind)

  if node_suffix then
    local override_mod = load_module(base_path .. "." .. node_suffix)
    local override_builder = resolve_builder_from_module(override_mod)
    if type(override_builder) == "function" then
      return override_builder
    end
  end

  local base_mod = load_module(base_path)
  return resolve_builder_from_module(base_mod)
end

-- Resolve action builder for action name and node kind
function M.resolve(action_name, node_kind)
  for _, scope in ipairs(action_scopes) do
    local builder = resolve_from_scope(action_name, node_kind, scope)
    if type(builder) == "function" then
      return builder
    end
  end

  return nil
end

-- Build executable action closure for resolved builder
function M.build(action_name, node_kind, ctx)
  local builder = M.resolve(action_name, node_kind)
  if type(builder) ~= "function" then
    return nil
  end

  return builder(ctx or {}, node_kind)
end

-- Wrap action name into a builder function
function M.builder(action_name)
  return function(ctx, node_kind)
    return M.build(action_name, node_kind, ctx)
  end
end

setmetatable(M, {
  -- Expose action-name builder API like resolver.rename
  __index = function(_, key)
    if type(key) ~= "string" or key == "" then
      return nil
    end

    return M.builder(key)
  end,
})

return M
