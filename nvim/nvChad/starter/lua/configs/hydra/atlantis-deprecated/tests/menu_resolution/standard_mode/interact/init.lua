local M = "configs.hydra.atlantis-deprecated.tests.menu_resolution.standard_mode.interact."

return function()
  describe("Interact", function()
    require(M .. "column")()
    require(M .. "reopen_depth")()
    require(M .. "view_call_hierarchy")()
    require(M .. "comment")()
    require(M .. "comment_anchor")()
  end)
end
