local M = "configs.hydra.atlantis.tests.menu_resolution.container_mode.interact."

return function()
  describe("Interact", function()
    require(M .. "column")()
    require(M .. "reopen")()
  end)
end
