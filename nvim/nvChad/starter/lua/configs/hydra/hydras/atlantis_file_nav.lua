local atlantis = require("configs.hydra.atlantis")

return {
  open = function(menu_opts, hydra_opts)
    atlantis.open_container(menu_opts, hydra_opts)
  end,
}
