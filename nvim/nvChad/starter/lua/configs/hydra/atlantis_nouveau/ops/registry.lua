local actions = "configs.hydra.atlantis_nouveau.ops.actions"

return {
  rename          = { fn = require(actions .. ".rename"),          key = "r", icon = "✎", label = "Rename"      },
  yank            = { fn = require(actions .. ".yank"),            key = "y", icon = "y", label = "Yank"        },
  delete          = { fn = require(actions .. ".delete"),          key = "d", icon = "x", label = "Delete"      },
  change          = { fn = require(actions .. ".change"),          key = "c", icon = "✎", label = "Change"      },
  substitute      = { fn = require(actions .. ".substitute"),      key = "s", icon = "s", label = "Substitute"  },
  exchange        = { fn = require(actions .. ".exchange"),        key = "x", icon = "x", label = "Exchange"    },
  split_join      = { fn = require(actions .. ".split_join").run,         key = "M", icon = "󰾈", label = "Split/Join"  },
  recase          = { fn = require(actions .. ".recase").run,             key = "E", icon = "󰬴", label = "Re-case"     },
  swap_prev       = { fn = require(actions .. ".swap_sibling").with_prev, key = "J", icon = "󰜸", label = "Swap ↑ prev" },
  swap_next       = { fn = require(actions .. ".swap_sibling").with_next, key = "K", icon = "󰜶", label = "Swap ↓ next" },
  lsp_code_actions= { fn = require(actions .. ".lsp_code_actions").run,   key = "A", icon = "", label = "LSP Actions" },
  refactor        = { fn = require(actions .. ".refactor").run,           key = "R", icon = "", label = "Refactor"    },
}
