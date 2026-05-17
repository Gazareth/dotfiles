local p = "configs.hydra.atlantis_nouveau.ops.actions.modify"
return {
  rename     = require(p .. ".rename"),
  recase     = require(p .. ".recase"),
  transform  = require(p .. ".transform"),
  split_join = require(p .. ".split_join"),
  swap       = require(p .. ".swap"),
  yank       = require(p .. ".yank"),
  delete     = require(p .. ".delete"),
  change     = require(p .. ".change"),
  substitute = require(p .. ".substitute"),
  exchange   = require(p .. ".exchange"),
}
