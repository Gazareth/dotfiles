local M = "configs.hydra.atlantis-deprecated.tests.menu_resolution.container_mode.navigate."

return function()
  describe("Navigate -", function()
    require(M .. "column")()
  end)
end
