-- JS/TS grammar sites (standard menu). Skips when Tree-sitter language is unavailable.
-- Case shape: configs.hydra.atlantis.tests.menu_case

local menu_case = require("configs.hydra.atlantis.tests.menu_case")
local supported = require("configs.hydra.atlantis.anchor.probe.treesitter.constants").supported_nodes

describe("[Atlantis standard menu] JS/TS", function()
  describe("typescript", function()
    local import_line = { [[import { x } from "m"]] }
    local export_line = { "export const a = 1" }

    menu_case.run_treesitter_cases("typescript", "typescript", {
      { "Import statement", import_line, 1, "import", supported.generic },
      { "Export statement", export_line, 1, "export", supported.generic },
    })
  end)
end)
