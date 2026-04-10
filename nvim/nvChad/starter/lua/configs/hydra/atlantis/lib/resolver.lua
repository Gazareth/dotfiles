local M = {}

local default_scopes = { "specific", "common" }

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

local function normalize_kind(kind)
  if type(kind) ~= "string" or kind == "" then
    return nil
  end

  local normalized = kind:gsub("[^%w_]", "_")
  if normalized == "" then
    return nil
  end

  return normalized
end

local function build_export(mod)
  if type(mod) ~= "table" or type(mod.build) ~= "function" then
    return nil
  end
  return mod.build
end

local function resolve_from_scope(root_prefix, action_name, kind, scope)
  if type(root_prefix) ~= "string" or root_prefix == "" then
    return nil
  end
  if type(action_name) ~= "string" or action_name == "" then
    return nil
  end

  local base_path = root_prefix .. "." .. scope .. "." .. action_name
  local suffix = normalize_kind(kind)

  if suffix then
    local override_mod = load_module(base_path .. "." .. suffix)
    local override_build = build_export(override_mod)
    if type(override_build) == "function" then
      return override_build
    end
  end

  local base_mod = load_module(base_path)
  return build_export(base_mod)
end

function M.resolve(root_prefix, action_name, kind, opts)
  opts = type(opts) == "table" and opts or {}
  local scopes = type(opts.scopes) == "table" and opts.scopes or default_scopes

  for _, scope in ipairs(scopes) do
    local build = resolve_from_scope(root_prefix, action_name, kind, scope)
    if type(build) == "function" then
      return build
    end
  end

  return nil
end

return M
