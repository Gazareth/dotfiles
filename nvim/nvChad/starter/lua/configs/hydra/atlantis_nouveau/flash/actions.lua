local M = {}

local NAV_ORDER = require("configs.hydra.atlantis_nouveau.menu.sections.navigate").nav_order
local helpers   = require("configs.hydra.atlantis_nouveau.flash.helpers")

-- Builds the full flash actions table.
-- state: shared mutable context —
--   { nav_item, pending_action, tab_pressed, shift_tab_pressed, hint_win, hint_buf }
-- All closures read/write state fields; hint_win/hint_buf are set by init after this call.
function M.build(nav, result, plugins, state)
  local actions = {}

  -- Nav keys: each sets state.nav_item and closes flash.
  for _, entry in ipairs(NAV_ORDER) do
    local target = nav[entry.field]
    if target then
      actions[entry.key] = function(_s, _c)
        state.nav_item = target
        return false
      end
    end
  end

  -- % switch: comment ↔ statement (treated as a nav jump).
  local switch_item = result.comment_range and { range = result.comment_range }
                   or result.associated_statement
  if switch_item then
    actions["%"] = function(_s, _c)
      state.nav_item = switch_item
      return false
    end
  end

  -- Node-operation keys sourced from the registry.
  -- Adding an op to registry.action_ops is sufficient; nothing to change here.
  local registry = require("configs.hydra.atlantis_nouveau.ops.registry")
  local function set_pending(fn) state.pending_action = fn end
  for _, op in ipairs(registry.available_actions(result, plugins)) do
    actions[op.key] = registry.as_flash_handler(op, result, set_pending)
  end

  -- Mode cycling.
  actions["<Tab>"] = function(_s, _c)
    state.tab_pressed = true
    return false
  end

  actions["<S-Tab>"] = function(_s, _c)
    state.shift_tab_pressed = true
    return false
  end

  -- UI keys.
  actions["q"] = function(_s, _c)
    return false  -- triggers not action_called cleanup in init
  end

  actions["?"] = function(_s, _c)
    if state.hint_win and vim.api.nvim_win_is_valid(state.hint_win) then
      helpers.close_hint_win(state.hint_win, state.hint_buf)
      state.hint_win, state.hint_buf = nil, nil
    else
      state.hint_win, state.hint_buf = helpers.open_hint_win()
    end
    -- return nothing: keeps flash open
  end

  return actions
end

return M
