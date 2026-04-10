-- Build action callback lookup tables from node action registry and adapter overrides
local node_actions = require("configs.hydra.atlantis.anchor.registry.actions")
local supported_nodes = require("configs.hydra.atlantis.anchor.probe.treesitter.constants").supported_nodes

local M = {}

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

-- Adapter-specific lookup callbacks keyed by node kind
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
}

-- Build full lookup by combining base node actions and adapter extensions
function M.build(node_kind, runtime_ctx, adapter)
  local base_lookup = build_node_action_lookup(node_kind, runtime_ctx)
  local lookup_builder = lookup_specs[node_kind]
  if type(lookup_builder) ~= "function" then
    return base_lookup
  end

  return merge_lookup(base_lookup, lookup_builder(adapter, runtime_ctx))
end

return M
