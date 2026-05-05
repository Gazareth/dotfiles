local M = "configs.hydra.atlantis-deprecated.tests.menu_resolution."

describe("[Standard mode]", function()
  require(M .. "common.footer")()
  require(M .. "common.title")()
  describe("Main grid -", function()
    require(M .. "common.main_grid")()
    require(M .. "standard_mode.navigate")()
    require(M .. "standard_mode.interact")()
    require(M .. "standard_mode.create")()
    require(M .. "standard_mode.anchor_resolution")()
  end)
end)
