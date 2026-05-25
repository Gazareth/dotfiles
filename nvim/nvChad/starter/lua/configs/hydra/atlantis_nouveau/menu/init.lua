local make_hydra     = require("configs.hydra.lib.make_hydra")
local standard       = require("configs.hydra.atlantis_nouveau.menu.modes.standard")
local highlight_node = require("configs.hydra.atlantis_nouveau.menu.highlight_node")

local M = {}

local badge = require("configs.hydra.atlantis_nouveau.menu.badge")

local KICKER = "🔱 Atlantis 🔱"

local function menu_title(result)
  -- "!" prefix bypasses format_title's colon-based role/name parsing (the
  -- L{start}:{end} format contains a literal colon that would be mangled).
  return "!" .. badge.long(result)
end

function M.open(result)
  -- Apply a transient highlight over the node that is being hovered over
  -- Also get an on_exit callback that clears the highlight when the menu is closed
  local on_exit  = highlight_node.apply(result.bufnr, result.range)

  local registry = require("configs.hydra.atlantis_nouveau.ops.registry")
  local common_actions = {
    registry.as_menu_item(registry.yank,   result),
    registry.as_menu_item(registry.delete, result),
    registry.as_menu_item(registry.change, result),
  }

  local plugins  = require("configs.hydra.atlantis_nouveau.plugins")
  local has_flash = plugins.has("flash", "flash.nvim")
  local has_namu  = plugins.has("namu.selecta.selecta", "namu.nvim")

  local OVERFLOW_THRESHOLD = 9
  local is_overflow = result.outline and #result.outline > OVERFLOW_THRESHOLD

  local swap_line, extra_line = {}, {}
  for _, entry in ipairs({
    { registry.swap_prev,  swap_line  },
    { registry.swap_next,  swap_line  },
    { registry.substitute, extra_line },
    { registry.exchange,   extra_line },
  }) do
    local op, line = entry[1], entry[2]
    if registry.is_available(op, result, plugins) then
      table.insert(line, registry.as_menu_item(op, result))
    end
  end
  local header_actions = {}
  if #swap_line  > 0 then table.insert(header_actions, swap_line)  end
  if #extra_line > 0 then table.insert(header_actions, extra_line) end

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
      {
        "<S-Tab>",
        function()
          skip_highlight_cleanup    = true
          result._highlight_cleanup = on_exit
          if result.outline and #result.outline > 0 then
            require("configs.hydra.atlantis_nouveau.namu").open(result)
          else
            -- No children: skip namu and continue backwards to flash.
            require("configs.hydra.atlantis_nouveau.flash").open(result)
          end
        end,
        { exit = true, desc = false },
      },
    }
  end

  local footer_left
  if is_overflow and has_namu then
    footer_left = "[?] toggle hint  [<Tab>] select child..."
  elseif not is_overflow and has_flash then
    footer_left = "[?] toggle hint  [<S-Tab>/<Tab>] cycle selection mode"
  else
    footer_left = "[?] toggle hint"
  end

  make_hydra.open({
    title          = "Atlantis",
    common_actions = common_actions,
    header_actions = header_actions,
    sections       = sections,
    on_exit        = function()
      if not skip_highlight_cleanup then on_exit() end
    end,
    hint_opts      = {
      title        = menu_title(result),
      title_kicker = KICKER,
      footer = {
        left  = footer_left,
        right = "[q]/[Esc] exit",
      },
    },
    extra_heads    = extra_heads,
  })
end

return M
