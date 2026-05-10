return {
  rename            = { fn = require("configs.hydra.atlantis_nouveau.ops.actions.rename"), key = "r", icon = "✎", label = "Rename" },
  yank              = { fn = require("configs.hydra.atlantis_nouveau.ops.actions.yank"),   key = "y", icon = "y", label = "Yank"   },
  delete            = { fn = require("configs.hydra.atlantis_nouveau.ops.actions.delete"), key = "d", icon = "x", label = "Delete" },
  change            = { fn = require("configs.hydra.atlantis_nouveau.ops.actions.change"), key = "c", icon = "✎", label = "Change" },
  substitute        = { fn = require("configs.hydra.atlantis_nouveau.ops.actions.substitute"), key = "s", icon = "s", label = "Substitute" },
  exchange          = { fn = require("configs.hydra.atlantis_nouveau.ops.actions.exchange"),   key = "x", icon = "x", label = "Exchange"   },
}
