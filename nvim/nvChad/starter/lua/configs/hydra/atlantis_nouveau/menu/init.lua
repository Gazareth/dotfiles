local make_hydra     = require("configs.hydra.lib.make_hydra")
local standard       = require("configs.hydra.atlantis_nouveau.menu.modes.standard")
local highlight_node = require("configs.hydra.atlantis_nouveau.menu.highlight_node")

local M = {}

local function menu_title(result)
  local node = result.node and result.node.node
  if node and node.type and node.name then
    return node.type .. ": " .. node.name
  end
  return result.node_type or "node"
end

function M.open(result)
  -- Apply a transient highlight over the node that is being hovered over
  -- Also get an on_exit callback that clears the highlight when the menu is closed
  local on_exit = highlight_node.apply(result.bufnr, result.range)

  local registry = require("configs.hydra.atlantis_nouveau.ops.registry")
  local common_actions = {
    {
      key    = registry.yank.key,
      label  = "yank",
      action = function() registry.yank.fn(result) end,
    },
    {
      key    = registry.delete.key,
      label  = "delete",
      action = function() registry.delete.fn(result) end,
    },
    {
      key    = registry.change.key,
      label  = "change",
      action = function() registry.change.fn(result) end,
    },
  }

  make_hydra.open({
    title          = menu_title(result),
    common_actions = common_actions,
    sections       = standard.sections(result),
    on_exit        = on_exit,
  })
end

return M
