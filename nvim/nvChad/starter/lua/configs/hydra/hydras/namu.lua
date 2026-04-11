local make_hydra = require("configs.hydra.lib.make_hydra")
local namu = require("configs.hydra.namu")

local M = {}

function M.open(spec_opts, hydra_opts)
  spec_opts = type(spec_opts) == "table" and spec_opts or {}
  local spec = vim.tbl_extend("force", {
    title = "Namu",
    sections = { namu.symbols, namu.diagnostics, namu.call_hierarchy },
  }, spec_opts)
  make_hydra(spec, hydra_opts):open()
end

return M
