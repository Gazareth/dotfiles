local M = "configs.hydra.atlantis.tests.menu_resolution."

describe("[Container mode]", function()
  describe("Main grid -", function()
    require(M .. "container_mode.navigate")()
    require(M .. "container_mode.interact")()
    require(M .. "container_mode.create")()
    require(M .. "container_mode.anchor_resolution")()
  end)
end)
