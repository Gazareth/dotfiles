local parse_node = require("configs.hydra.atlantis.treesitter")
local build_node_info = require("configs.hydra.atlantis.treesitter.common.node_info").build_node_info
local select_anchor_node_info = require("configs.hydra.atlantis.treesitter.anchor").select_node_info
local filter_allowed_items = require("configs.hydra.atlantis.ops.filter").filter_items
local descriptor_helpers = require("configs.hydra.atlantis.menu.nodes.common.helpers")
local registry = require("configs.hydra.atlantis.menu.nodes.registry")
local runtime_context = require("configs.hydra.atlantis.runtime.context")

local M = {}

-- Format cursor row and column for semantic status messages
local function format_cursor(cursor)
  if type(cursor) ~= "table" then
    return "?:?"
  end

  return tostring(cursor.row or "?") .. ":" .. tostring(cursor.col or "?")
end

-- Notify semantic mapping status for unknown or unsupported nodes
local function notify_semantic_status(parsed)
  local semantic = parsed and parsed.semantic
  if type(semantic) ~= "table" then
    return
  end

  if semantic.status == "unknown-node" then
    local message = table.concat({
      "Atlantis does not recognize this node.",
      "node=" .. tostring(semantic.raw_node_type),
      "language=" .. tostring(semantic.language),
      "cursor=" .. format_cursor(semantic.cursor),
      "parent=" .. tostring(semantic.parent_node_type),
      "named=" .. tostring(semantic.named),
    }, " ")

    vim.notify(message, vim.log.levels.INFO)
    return
  end

  if semantic.status == "unsupported-language" then
    local message = table.concat({
      "Atlantis language support is disabled for this buffer.",
      "language=" .. tostring(semantic.language),
      "node=" .. tostring(semantic.raw_node_type),
      "cursor=" .. format_cursor(semantic.cursor),
    }, " ")

    vim.notify(message, vim.log.levels.WARN)
  end
end

-- Normalize node descriptor and filter menu items by action ids
local function finalize_spec(spec, node_info, parsed, capabilities)
  local action_ids = type(capabilities) == "table" and capabilities.action_ids or nil
  spec.items = filter_allowed_items(parsed, spec.items, action_ids)
  parsed.normalized_node = descriptor_helpers.normalize_node_descriptor(node_info, parsed)
  spec.node = parsed.normalized_node
  return spec
end

-- Build node menu spec from runtime context with safe fallback
function M.get_node_menu_spec(runtime_ctx)
  local ctx = runtime_ctx
  if type(ctx) ~= "table" then
    ctx = runtime_context.build()
  end

  local cursor_node_info = ctx.cursor_node_info
  if not cursor_node_info then
    return {
      __abort_open = true,
      __abort_message = "Treewalker menu unavailable: no Treesitter node at cursor.",
    }
  end

  -- Resolve anchor parse and capability payload from runtime context
  local node_info = ctx.anchor_node_info or select_anchor_node_info(cursor_node_info)
  local parsed = ctx.parsed_anchor or parse_node(node_info)
  local capabilities = ctx.capabilities
  notify_semantic_status(parsed)

  -- Try node-kind-specific builder from registry
  local builder = registry.get_builder(parsed and parsed.node_kind)
  if type(builder) == "function" then
    local ok, spec = pcall(builder, node_info, parsed, ctx)
    if ok and type(spec) == "table" then
      return finalize_spec(spec, node_info, parsed, capabilities)
    end

    vim.notify("Falling back to generic Treesitter menu section.", vim.log.levels.WARN)
  end

  -- Fallback to generic capability-driven builder
  local fallback = registry.get_generic_builder()
  local spec = fallback(node_info, parsed, ctx)
  return finalize_spec(spec, node_info, parsed, capabilities)
end

return M
