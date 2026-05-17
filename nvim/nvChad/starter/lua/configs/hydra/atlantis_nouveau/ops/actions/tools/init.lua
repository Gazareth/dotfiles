local p = "configs.hydra.atlantis_nouveau.ops.actions.tools"
return {
  lsp         = require(p .. ".lsp"),
  refactoring = require(p .. ".refactoring"),
}
