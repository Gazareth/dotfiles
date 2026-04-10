local build_node_info = require("configs.hydra.atlantis.anchor.probe.treesitter.node_info").build_node_info
local resolve_language_mapping = require("configs.hydra.atlantis.anchor.languages").resolve

local M = {}

-- Build semantic resolver options from active tree-sitter config
local function build_resolve_options(config)
  return {
    safe_languages = config.safe_languages,
    languages = config.languages,
  }
end

-- Check whether node is an "anchor" for current language
local function is_actionable(node_info, resolve_options)
  local semantic = resolve_language_mapping(node_info, resolve_options)
  if semantic and semantic.actionable == true then
    return true, semantic
  end

  return false, semantic
end

-- Collect potential "anchor" candidate nodes from cursor node to root
function M.collect(node_info, config)
  local current = node_info and node_info.node or nil
  local candidate_chain = {}
  local resolve_options = build_resolve_options(config or {})

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
      candidate_chain[#candidate_chain + 1] = {
        node_info = candidate,
        semantic = semantic,
      }
    end

    current = current:parent()
  end

  return candidate_chain
end

return M