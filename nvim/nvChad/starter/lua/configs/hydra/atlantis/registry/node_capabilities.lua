local node_actions = require("configs.hydra.atlantis.registry.node_actions")
local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes
local parameter_sibling = require("configs.hydra.atlantis.ops.function.parameter.sibling")
local navigate = require("configs.hydra.atlantis.menu.nodes.function.lib.navigate")

local M = {}

-- Adapter factories for node kinds that expose richer operations
local adapter_specs = {
  [supported_nodes.parameter] = function(runtime_ctx)
    return parameter_sibling.create(runtime_ctx)
  end,
}

-- Build direct action callback lookup from node action registry
local function build_node_action_lookup(node_kind, runtime_ctx)
  local action_names = node_actions.action_names_by_node_kind[node_kind]
  if type(action_names) ~= "table" then
    return nil
  end

  local lookup = {}
  for action_name, enabled in pairs(action_names) do
    if enabled == true then
      local action = node_actions.build(node_kind, action_name, runtime_ctx)
      if type(action) == "function" then
        lookup[action_name] = action
      end
    end
  end

  return lookup
end

-- Merge two callback lookup tables with extra keys overriding base
local function merge_lookup(base, extra)
  local merged = {}

  if type(base) == "table" then
    for key, value in pairs(base) do
      merged[key] = value
    end
  end

  if type(extra) == "table" then
    for key, value in pairs(extra) do
      merged[key] = value
    end
  end

  return merged
end

-- Build declarative submenu specs for function anchors
local function build_function_submenu_specs(runtime_ctx)
  local parsed = type(runtime_ctx) == "table" and runtime_ctx.parsed or nil
  local targets = type(parsed) == "table" and type(parsed.targets) == "table" and parsed.targets or {}
  local parameter_targets = type(targets.parameters) == "table" and targets.parameters or {}
  local nested_function_targets = type(targets.nested_functions) == "table" and targets.nested_functions or {}
  local assignment_targets = type(targets.assignments) == "table" and targets.assignments or {}

  return {
    {
      id = "parameters",
      order = 10,
      key = "p",
      icon = ">",
      label = "Parameters...",
      is_available = function()
        return type(targets.parameter_container) == "table"
      end,
      open = function()
        local parameter_anchor = parameter_targets[1] or targets.parameter_container
        if type(parameter_anchor) == "table" then
          navigate.navigate_and_open_at_depth(parameter_anchor, "lowest_node")()
        end
      end,
    },
    {
      id = "body",
      order = 20,
      key = "b",
      icon = ">",
      label = "Body...",
      is_available = function()
        return #nested_function_targets > 0 or #assignment_targets > 0
      end,
      open = function()
        local body_start = nested_function_targets[1] or assignment_targets[1]
        if type(body_start) == "table" then
          navigate.navigate_and_open_at_depth(body_start, "depth_1")()
        end
      end,
    },
  }
end

-- Extend capability lookup with node-kind-specific callbacks
local lookup_specs = {
  [supported_nodes.parameter] = function(adapter)
    if type(adapter) ~= "table" then
      return nil
    end

    return {
      rename = function()
        adapter:rename()
      end,
      remove = function()
        adapter:remove()
      end,
      has_previous = function()
        return type(adapter.sibling) == "table" and adapter.sibling:has_previous() or false
      end,
      has_next = function()
        return type(adapter.sibling) == "table" and adapter.sibling:has_next() or false
      end,
      has_swappable = function()
        return type(adapter.sibling) == "table" and adapter.sibling:has_swappable() or false
      end,
      jump_next = function()
        if type(adapter.sibling) == "table" and type(adapter.sibling.jump_next) == "function" then
          adapter.sibling.jump_next()
        end
      end,
      jump_previous = function()
        if type(adapter.sibling) == "table" and type(adapter.sibling.jump_previous) == "function" then
          adapter.sibling.jump_previous()
        end
      end,
      swap_next = function()
        if type(adapter.sibling) == "table" and type(adapter.sibling.swap_next) == "function" then
          adapter.sibling.swap_next()
        end
      end,
      swap_previous = function()
        if type(adapter.sibling) == "table" and type(adapter.sibling.swap_previous) == "function" then
          adapter.sibling.swap_previous()
        end
      end,
      jump_prompt = function()
        if type(adapter.sibling) == "table" and type(adapter.sibling.jump_prompt) == "function" then
          adapter.sibling.jump_prompt()
        end
      end,
      swap_prompt = function()
        if type(adapter.sibling) == "table" and type(adapter.sibling.swap_prompt) == "function" then
          adapter.sibling.swap_prompt()
        end
      end,
    }
  end,
  [supported_nodes.fn] = function(_, runtime_ctx)
    local submenu_specs = build_function_submenu_specs(runtime_ctx)
    local lookup = {}
    for _, spec in ipairs(submenu_specs) do
      local token = type(spec.id) == "string" and spec.id or nil
      if token then
        lookup["has_" .. token .. "_submenu"] = function()
          return type(spec.is_available) == "function" and spec.is_available() == true or false
        end
        lookup["open_" .. token .. "_submenu"] = function()
          if type(spec.open) == "function" then
            spec.open()
          end
        end
      end
    end

    return lookup
  end,
}

-- Submenu spec builders by node kind
local submenu_specs = {
  [supported_nodes.fn] = function(_, runtime_ctx)
    return build_function_submenu_specs(runtime_ctx)
  end,
}

-- Resolve allowed action ids by node kind
function M.by_node_kind(node_kind)
  return node_actions.get_node_action_ids(node_kind)
end

-- Build node adapter instance from adapter spec table
function M.build_adapter(node_kind, runtime_ctx)
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

-- Build full capability payload for menu and action wiring
function M.build(node_kind, runtime_ctx)
  local adapter = M.build_adapter(node_kind, runtime_ctx)
  local base_lookup = build_node_action_lookup(node_kind, runtime_ctx)
  local lookup_builder = lookup_specs[node_kind]
  local submenu_builder = submenu_specs[node_kind]
  local lookup = base_lookup
  if type(lookup_builder) == "function" then
    lookup = merge_lookup(base_lookup, lookup_builder(adapter, runtime_ctx))
  end

  local node_submenus = nil
  if type(submenu_builder) == "function" then
    node_submenus = submenu_builder(adapter, runtime_ctx)
  end

  return {
    node_kind = node_kind,
    action_ids = M.by_node_kind(node_kind),
    adapter = adapter,
    lookup = lookup,
    submenus = node_submenus,
  }
end

return M
