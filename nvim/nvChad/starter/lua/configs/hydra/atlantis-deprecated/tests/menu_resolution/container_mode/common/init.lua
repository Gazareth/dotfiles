local M = "configs.hydra.atlantis-deprecated.tests.menu_resolution.container_mode.common."

return function()
  describe("Common -", function()
    require(M .. "reopen")()
  end)
end
