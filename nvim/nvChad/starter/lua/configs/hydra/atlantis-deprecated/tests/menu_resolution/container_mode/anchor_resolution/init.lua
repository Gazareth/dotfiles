local M = "configs.hydra.atlantis-deprecated.tests.menu_resolution.container_mode.anchor_resolution."

return function()
  describe("Anchor resolution", function()
    require(M .. "content")()
  end)
end
