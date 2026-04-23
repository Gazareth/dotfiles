local M = "configs.hydra.atlantis.tests.menu_resolution.container_mode.create."

return function()
  describe("Create", function()
    require(M .. "placeholder")()
  end)
end
