local a        = "configs.hydra.atlantis_nouveau.ops.actions"
local modify   = require(a .. ".modify")
local tools = require(a .. ".tools")

return {
  rename          = { fn = modify.rename,                  key = "r", icon = "✎",  label = "Rename"      },
  yank            = { fn = modify.yank,                    key = "y", icon = "y",  label = "Yank"        },
  delete          = { fn = modify.delete,                  key = "d", icon = "x",  label = "Delete"      },
  change          = { fn = modify.change,                  key = "c", icon = "✎",  label = "Change"      },
  substitute      = { fn = modify.substitute,              key = "s", icon = "s",  label = "Substitute"  },
  exchange        = { fn = modify.exchange,                key = "x", icon = "x",  label = "Exchange"    },
  split_join      = { fn = modify.split_join.run,          key = "M", icon = "󰾈",  label = "Split/Join"  },
  recase          = { fn = modify.recase.run,              key = "E", icon = "󰬴",  label = "Re-case"     },
  swap_prev       = { fn = modify.swap.with_prev,          key = "J", icon = "󰜸",  label = "Swap ↑ prev" },
  swap_next       = { fn = modify.swap.with_next,          key = "K", icon = "󰜶",  label = "Swap ↓ next" },
  lsp_code_actions= { fn = tools.lsp.run,              key = "A", icon = "",  label = "LSP Actions" },
  refactor     = { fn = tools.refactoring.run,     key = "R", icon = "",  label = "Refactor"    },
}
