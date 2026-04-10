local build_node_info = require("configs.hydra.atlantis.anchor.probe.treesitter.node_info").build_node_info
local resolve_language_mapping = require("configs.hydra.atlantis.anchor.registry.languages").resolve
local treesitter_config = require("configs.hydra.atlantis.anchor.probe.treesitter.config")
local options = require("configs.hydra.atlantis.anchor.build.find_from_node.options")

local M = {}

-- Check whether node is actionable under semantic mappings
local function is_actionable(node_info, resolve_options)
  local semantic = resolve_language_mapping(node_info, resolve_options)
  if semantic and semantic.actionable == true then
    return true, semantic
  end

  return false, semantic
end

-- Collect actionable nodes from cursor node to root
local function collect_candidates(node_info, resolve_options)
  local current = node_info and node_info.node or nil
  local candidates = {}

  while current do
    local candidate = build_node_info({
      bufnr = node_info.bufnr,
      node = current,
    })

    local actionable, semantic = false, nil
    if candidate then
      actionable, semantic = is_actionable(candidate, resolve_options)
    end

    if candidate and actionable then
      candidates[#candidates + 1] = {
        node_info = candidate,
        semantic = semantic,
      }
    end

    current = current:parent()
  end

  return candidates
end

-- Build actionable candidate chain used while finding anchor node
function M.get_candidates(node_info)
  if not node_info or not node_info.node then
    return {}
  end

  local config = treesitter_config.get()
  local resolve_options = options.build_resolve_options(config)
  return collect_candidates(node_info, resolve_options)
end

-- Find selected anchor index inside candidate chain
function M.find_candidate_index(candidates, selected_node_info)
  if type(candidates) ~= "table" or not selected_node_info or not selected_node_info.node then
    return nil
  end

  local ok, selected_id = pcall(function()
    return selected_node_info.node:id()
  end)
  if not ok then
    return nil
  end

  for index, entry in ipairs(candidates) do
    local match_ok, entry_id = pcall(function()
      return entry.node_info.node:id()
    end)
    if match_ok and entry_id == selected_id then
      return index
    end
  end

  return nil
end

return M
