local hydra_spec = require("configs.hydra.lib.hydra_spec")
local namu = require("configs.hydra.namu")

local M = {}

function M.open(spec_opts, hydra_opts)
  spec_opts = type(spec_opts) == "table" and spec_opts or {}
  local spec = vim.tbl_extend("force", {
    title = "Namu",
    sections = { namu.symbols, namu.diagnostics, namu.call_hierarchy },
  }, spec_opts)
  hydra_spec.open(spec, hydra_opts)
end

return M
