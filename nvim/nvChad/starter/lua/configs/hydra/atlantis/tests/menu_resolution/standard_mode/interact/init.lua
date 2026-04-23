local M = "configs.hydra.atlantis.tests.menu_resolution.standard_mode.interact."

return function()
  describe("Interact", function()
    require(M .. "column")()
    require(M .. "reopen_depth")()
    require(M .. "view_call_hierarchy")()
  end)
end
