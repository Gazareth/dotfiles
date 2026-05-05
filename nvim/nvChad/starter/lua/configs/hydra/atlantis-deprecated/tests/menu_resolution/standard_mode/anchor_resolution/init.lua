local M = "configs.hydra.atlantis-deprecated.tests.menu_resolution.standard_mode.anchor_resolution."

return function()
  describe("Anchor resolution -", function()
    require(M .. "actions")()
    require(M .. "content")()
  end)
end
