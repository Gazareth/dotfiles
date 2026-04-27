local M = "configs.hydra.atlantis.tests.menu_resolution.standard_mode.navigate.sibling."

return function()
  describe("Sibling -", function()
    require(M .. "core")()
    require(M .. "wrap")()
    require(M .. "standard")()
    require(M .. "list")()
  end)
end
