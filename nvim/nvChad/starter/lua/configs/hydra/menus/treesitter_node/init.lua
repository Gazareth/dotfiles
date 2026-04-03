local parse_node = require("configs.hydra.treesitter")
local build_node_info = require("configs.hydra.treesitter.lib").build_node_info
local supported_nodes = require("configs.hydra.treesitter.lib.constants").supported_nodes
local generic = require("configs.hydra.menus.treesitter_node.generic")
local identifier = require("configs.hydra.menus.treesitter_node.identifier")
local function_spec = require("configs.hydra.menus.treesitter_node.function")

local M = {}

local spec_builders = {
  [supported_nodes.identifier] = identifier.build,
  [supported_nodes["function"]] = function_spec.build,
}

function M.get_node_menu_spec()
  local node_info = build_node_info()
  if not node_info then
    return {
      __abort_open = true,
      __abort_message = "Treewalker menu unavailable: no Treesitter node at cursor.",
    }
  end

  local parsed = parse_node(node_info)
  local builder = spec_builders[parsed and parsed.node_kind]

  if type(builder) == "function" then
    local ok, spec = pcall(builder, node_info, parsed)
    if ok and type(spec) == "table" then
      return spec
    end

    vim.notify("Falling back to generic Treesitter menu section.", vim.log.levels.WARN)
  end

  return generic.build(node_info, parsed)
end

return M
