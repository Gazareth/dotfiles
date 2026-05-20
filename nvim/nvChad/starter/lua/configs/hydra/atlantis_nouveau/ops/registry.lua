local a        = "configs.hydra.atlantis_nouveau.ops.actions"
local modify   = require(a .. ".modify")
local tools    = require(a .. ".tools")
local contents = require(a .. ".contents")

local function has_prev(r)  return r.navigation and r.navigation.prev_sibling end
local function has_next(r)  return r.navigation and r.navigation.next_sibling end
local function has_sub(_r, p) return p.has("substitute", "substitute.nvim") end
local function has_exch(_r, p) return p.has_exchange() end

local M = {
  rename          = { fn = modify.rename,                  key = "r", icon = "✎",  label = "Rename"      },
  yank            = { fn = modify.yank,                    key = "y", icon = "y",  label = "Yank"        },
  delete          = { fn = modify.delete,                  key = "d", icon = "x",  label = "Delete"      },
  change          = { fn = modify.change,                  key = "c", icon = "✎",  label = "Change"      },
  substitute      = { fn = modify.substitute,              key = "s", icon = "s",  label = "Substitute",  cond = has_sub  },
  exchange        = { fn = modify.exchange,                key = "x", icon = "x",  label = "Exchange",    cond = has_exch },
  split_join      = { fn = modify.split_join.run,          key = "M", icon = "󰾈",  label = "Split/Join"  },
  recase          = { fn = modify.recase.run,              key = "E", icon = "󰬴",  label = "Re-case"     },
  swap_prev       = { fn = modify.swap.with_prev,          key = "K", icon = "󰜸",  label = "Swap ↑",     cond = has_prev },
  swap_next       = { fn = modify.swap.with_next,          key = "J", icon = "󰜶",  label = "Swap ↓",     cond = has_next },
  lsp_code_actions    = { fn = tools.lsp.run,                       key = "A", icon = "",   label = "LSP Actions"         },
  refactor            = { fn = tools.refactoring.run,               key = "R", icon = "",   label = "Refactor"            },
  switch_to_comment   = { fn = contents.comment.switch_to_comment,   key = "%", icon = "󰅺", label = "Switch to comment"   },
  switch_to_statement = { fn = contents.comment.switch_to_statement, key = "%", icon = "󰅾", label = "Switch to commented code" },
}

-- Ordered list of ops shown in the standard menu and available in flash.
-- Adding an op here (with an optional cond) is sufficient for both modes to pick it up.
M.action_ops = {
  M.yank, M.delete, M.change,
  M.swap_prev, M.swap_next,
  M.substitute, M.exchange,
}

-- True when op has no condition or its condition is met.
function M.is_available(op, result, plugins)
  return not op.cond or op.cond(result, plugins)
end

-- Returns the subset of action_ops whose cond (if any) is satisfied.
function M.available_actions(result, plugins)
  local out = {}
  for _, op in ipairs(M.action_ops) do
    if not op.cond or op.cond(result, plugins) then
      out[#out + 1] = op
    end
  end
  return out
end

-- Build a make_hydra menu item: { key, label, action }
function M.as_menu_item(op, result)
  return { key = op.key, label = op.label:lower(), action = function() op.fn(result) end }
end

-- Build a flash.jump action handler that queues op via set_pending(fn).
-- Returns false to close flash without selecting a label target.
function M.as_flash_handler(op, result, set_pending)
  return function(_state, _char)
    set_pending(function() op.fn(result) end)
    return false
  end
end

return M
