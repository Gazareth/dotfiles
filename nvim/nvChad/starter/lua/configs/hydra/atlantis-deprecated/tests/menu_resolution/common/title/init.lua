local M = "configs.hydra.atlantis-deprecated.tests.menu_resolution.common.title."

return function()
  describe("Title", function()
    require(M .. "assignment")()
    require(M .. "boolean")()
    require(M .. "function")()
  end)
end
