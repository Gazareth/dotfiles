local make_hydra     = require("configs.hydra.lib.make_hydra")
local standard       = require("configs.hydra.atlantis_nouveau.menu.modes.standard")
local highlight_node = require("configs.hydra.atlantis_nouveau.menu.highlight_node")

local M = {}

local function menu_title(result)
  local classification = "Node"
  local name = ""

  if result.node then
    classification = result.node.kind:gsub("^%l", string.upper)
    local inner = result.node.node
    if inner and inner.type then
      classification = inner.type:gsub("^%l", string.upper)
      if inner.name and inner.name ~= "" then
        name = ' - "' .. inner.name .. '"'
      end
    end
  end

  local ts_type = result.node_type or "unknown"
  local r = result.range
  local range_str = string.format("[%s (%d:%d-%d:%d)]", ts_type, r.start_row + 1, r.start_col, r.end_row + 1, r.end_col)

  return "!" .. classification .. name .. " " .. range_str
end

function M.open(result)
  -- Apply a transient highlight over the node that is being hovered over
  -- Also get an on_exit callback that clears the highlight when the menu is closed
  local on_exit  = highlight_node.apply(result.bufnr, result.range)
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
  local has_flash      = pcall(require, "flash")
  local has_namu       = pcall(require, "namu.selecta.selecta")

  -- Support lazy-loaded plugins by checking the lazy.nvim registry
  local ok, lazy_config = pcall(require, "lazy.core.config")
  if ok and lazy_config.plugins then
    has_substitute = has_substitute or (lazy_config.plugins["substitute.nvim"] ~= nil)
    has_exchange   = has_exchange   or (lazy_config.plugins["vim-exchange"] ~= nil)
    has_flash      = has_flash      or (lazy_config.plugins["flash.nvim"] ~= nil)
    has_namu       = has_namu       or (lazy_config.plugins["namu.nvim"] ~= nil)
  end

  local OVERFLOW_THRESHOLD = 9
  local is_overflow = result.outline and #result.outline > OVERFLOW_THRESHOLD

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

  -- In overflow mode the normal Contents section is replaced with a single
  -- heading so the hint window stays compact; Tab opens namu directly.
  local sections
  if is_overflow then
    local all = standard.sections(result)
    sections = {}
    for _, s in ipairs(all) do
      if s.title == "Contents" then
        sections[#sections + 1] = {
          title = "Contents",
          items = { { heading = "[<Tab>] Select child..." } },
        }
      else
        sections[#sections + 1] = s
      end
    end
  else
    sections = standard.sections(result)
  end

  local skip_highlight_cleanup = false

  local extra_heads
  if is_overflow and has_namu then
    extra_heads = {
      {
        "<Tab>",
        function()
          -- Open namu but preserve M._mode — overflow is a display override only.
          local atlantis = require("configs.hydra.atlantis_nouveau")
          local saved    = atlantis._mode
          require("configs.hydra.atlantis_nouveau.namu").open(result)
          atlantis._mode = saved
        end,
        { exit = true, desc = false },
      },
    }
  elseif not is_overflow and has_flash then
    extra_heads = {
      {
        "<Tab>",
        function()
          skip_highlight_cleanup    = true
          result._highlight_cleanup = on_exit
          require("configs.hydra.atlantis_nouveau.flash").open(result)
        end,
        { exit = true, desc = false },
      },
    }
  end

  local footer_left
  if is_overflow and has_namu then
    footer_left = "[?] toggle hint  [<Tab>] select child..."
  elseif not is_overflow and has_flash then
    footer_left = "[?] toggle hint  [<Tab>] cycle selection mode"
  else
    footer_left = "[?] toggle hint"
  end

  make_hydra.open({
    title          = menu_title(result),
    common_actions = common_actions,
    header_actions = header_actions,
    sections       = sections,
    on_exit        = function()
      if not skip_highlight_cleanup then on_exit() end
    end,
    hint_opts      = {
      footer = {
        left  = footer_left,
        right = "[q]/[Esc] exit",
      },
    },
    extra_heads    = extra_heads,
  })
end

return M
