local p = "configs.hydra.atlantis_nouveau.ops.actions"
return {
  create   = require(p .. ".create"),
  modify   = require(p .. ".modify"),
  tools    = require(p .. ".tools"),
  contents = require(p .. ".contents"),
}
