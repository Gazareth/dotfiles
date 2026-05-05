local M = "configs.hydra.atlantis-deprecated.tests.menu_resolution.container_mode.outline."

return function()
  describe("Outline -", function()
    require(M .. "anchor")()
    require(M .. "outline_only_checks")()
    require(M .. "outline")()
  end)
end
