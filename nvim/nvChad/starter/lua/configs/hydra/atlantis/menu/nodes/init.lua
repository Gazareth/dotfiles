local parse_node = require("configs.hydra.atlantis.treesitter")
local build_node_info = require("configs.hydra.atlantis.treesitter.common.node_info").build_node_info
local supported_nodes = require("configs.hydra.atlantis.treesitter.common.constants").supported_nodes
local select_anchor_node_info = require("configs.hydra.atlantis.treesitter.anchor").select_node_info
local filter_allowed_items = require("configs.hydra.atlantis.ops.filter").filter_items
local descriptor_helpers = require("configs.hydra.atlantis.menu.nodes.common.helpers")
local generic = require("configs.hydra.atlantis.menu.nodes.generic")
local identifier = require("configs.hydra.atlantis.menu.nodes.identifier")
local assignment = require("configs.hydra.atlantis.menu.nodes.assignment")
local function_spec = require("configs.hydra.atlantis.menu.nodes.function")

local M = {}

-- Cursor text for status messages
local function format_cursor(cursor)
  if type(cursor) ~= "table" then
    return "?:?"
  end

  return tostring(cursor.row or "?") .. ":" .. tostring(cursor.col or "?")
end

-- Unknown and unsupported node messages
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

-- Menu builders by parsed node kind
local spec_builders = {
  [supported_nodes.identifier] = identifier.build,
  [supported_nodes.assignment] = assignment.build,
  [supported_nodes.fn] = function_spec.build,
}

-- Menu for the current Tree-sitter context
function M.get_node_menu_spec()
  local cursor_node_info = build_node_info()
  if not cursor_node_info then
    return {
      __abort_open = true,
      __abort_message = "Treewalker menu unavailable: no Treesitter node at cursor.",
    }
  end

  -- Pick the node used for actions
  local node_info = select_anchor_node_info(cursor_node_info)
  local parsed = parse_node(node_info)
  notify_semantic_status(parsed)
  local builder = spec_builders[parsed and parsed.node_kind]
  local spec = nil

  if type(builder) == "function" then
    local ok, built = pcall(builder, node_info, parsed)
    spec = built
    if ok and type(spec) == "table" then
      -- Remove actions the current node does not allow
      spec.items = filter_allowed_items(parsed, spec.items)
      parsed.normalized_node = descriptor_helpers.normalize_node_descriptor(node_info, parsed)
      spec.node = parsed.normalized_node
      return spec
    end

    vim.notify("Falling back to generic Treesitter menu section.", vim.log.levels.WARN)
  end

  spec = generic.build(node_info, parsed)
  spec.items = filter_allowed_items(parsed, spec.items)
  parsed.normalized_node = descriptor_helpers.normalize_node_descriptor(node_info, parsed)
  spec.node = parsed.normalized_node
  return spec
end

return M
