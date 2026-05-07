local jump = require("configs.hydra.atlantis_nouveau.ops.actions.jump")

return {
  jump_to_body        = { fn = jump.to_field("body"),        key = "b", icon = "↓", label = "Jump to body"        },
  jump_to_consequence = { fn = jump.to_field("consequence"), key = "b", icon = "↓", label = "Jump to body"        },
  jump_to_params      = { fn = jump.to_field("parameters"),  key = "p", icon = "→", label = "Jump to params"      },
  jump_to_condition = { fn = jump.to_field("condition"),  key = "c", icon = "?", label = "Jump to condition" },
  jump_lhs          = { fn = jump.to_field("lhs"),        key = "n", icon = "←", label = "Jump to name"      },
  jump_rhs          = { fn = jump.to_field("value"),      key = "v", icon = "→", label = "Jump to value"     },
  rename            = { fn = require("configs.hydra.atlantis_nouveau.ops.actions.rename"), key = "r", icon = "✎", label = "Rename" },
  yank              = { fn = require("configs.hydra.atlantis_nouveau.ops.actions.yank"),   key = "y", icon = "y", label = "Yank"   },
  delete            = { fn = require("configs.hydra.atlantis_nouveau.ops.actions.delete"), key = "d", icon = "x", label = "Delete" },
}
