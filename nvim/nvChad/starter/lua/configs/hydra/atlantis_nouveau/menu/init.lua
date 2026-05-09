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

  local has_substitute = pcall(require, "substitute")
  local has_exchange   = vim.fn.exists("g:loaded_exchange") == 1

  -- Support lazy-loaded plugins by checking the lazy.nvim registry
  local ok, lazy_config = pcall(require, "lazy.core.config")
  if ok and lazy_config.plugins then
    has_substitute = has_substitute or (lazy_config.plugins["substitute.nvim"] ~= nil)
    has_exchange   = has_exchange   or (lazy_config.plugins["vim-exchange"] ~= nil)
  end

  local header_actions = {}
  local extra_line = {}
  if has_substitute then
    table.insert(extra_line, {
      key    = registry.substitute.key,
      label  = "substitute",
      action = function() registry.substitute.fn(result) end,
    })
  end
  if has_exchange then
    table.insert(extra_line, {
      key    = registry.exchange.key,
      label  = "exchange",
      action = function() registry.exchange.fn(result) end,
    })
  end
  if #extra_line > 0 then
    table.insert(header_actions, extra_line)
  end

  make_hydra.open({
    title          = menu_title(result),
    common_actions = common_actions,
    header_actions = header_actions,
    sections       = standard.sections(result),
    on_exit        = on_exit,
  })
end

return M
