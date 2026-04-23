local M = "configs.hydra.atlantis.tests.menu_resolution.standard_mode.create."

return function()
  describe("Create -", function()
    require(M .. "placeholder")()
  end)
end
