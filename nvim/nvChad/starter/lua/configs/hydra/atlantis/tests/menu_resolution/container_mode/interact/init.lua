local M = "configs.hydra.atlantis.tests.menu_resolution.container_mode.interact."

return function()
  describe("Interact -", function()
    require(M .. "anchor")()
    require(M .. "outline_only_checks")()
    require(M .. "behaviour")()
    require(M .. "reopen")()
    require(M .. "outline")()
  end)
end
