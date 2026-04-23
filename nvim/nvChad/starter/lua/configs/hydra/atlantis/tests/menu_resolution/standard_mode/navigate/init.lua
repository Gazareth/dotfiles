local M = "configs.hydra.atlantis.tests.menu_resolution.standard_mode.navigate."

return function()
  describe("Navigate -", function()
    require(M .. "context")()
    require(M .. "layout")()
    require(M .. "sibling")()
    require(M .. "anchor")()
  end)
end
