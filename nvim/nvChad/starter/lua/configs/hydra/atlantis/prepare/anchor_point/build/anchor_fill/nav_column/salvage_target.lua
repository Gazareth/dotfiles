-- Resolve a raw Treesitter jump target to a focus node: use the language "actionable" map, and only
-- descend through *transparent* wrappers — nodes with exactly one named child (e.g. expression_statement
-- → assignment). Branching nodes (statement_block, if_statement, …) stay put so parent jumps do not
-- land on an arbitrary first statement.
local actionable = require("configs.hydra.atlantis.prepare.anchor_point.build.actionable")
local build_node_info = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.node_info").build_node_info
local treesitter_config = require("configs.hydra.atlantis.prepare.anchor_point.probe.treesitter.config")

local M = {}

local DEFAULT_MAX_HOPS = 32

function M.focus_node(node, bufnr, opts)
  if not node or bufnr == nil then
    return node
  end

  opts = opts or {}
  local config = opts.config or treesitter_config.get()
  local resolve_options = actionable.resolve_options_from_config(config)
  local max_hops = type(opts.max_hops) == "number" and opts.max_hops or DEFAULT_MAX_HOPS

  local current = node
  for _ = 1, max_hops do
    local info = build_node_info({ bufnr = bufnr, node = current })
    if info then
      local ok, _ = actionable.check(info, resolve_options)
      if ok then
        return current
      end
    end

    if current:named_child_count() ~= 1 then
      return current
    end

    local child = current:named_child(0)
    if not child then
      return current
    end
    current = child
  end

  return current
end

return M
