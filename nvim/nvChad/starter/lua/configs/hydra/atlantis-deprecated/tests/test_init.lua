-- Busted init for Atlantis specs. Runners: nvim/test_scripts/atlantis/run_tests.{ps1,sh}
-- (they print an aggregate summary after Plenary finishes). Optional: PLENARY_DIR.

local this_file = debug.getinfo(1, "S").source:sub(2)
this_file = vim.fn.fnamemodify(this_file, ":p")
local lua_root = vim.fn.fnamemodify(this_file, ":h:h:h:h:h")

vim.opt.rtp:prepend(lua_root)

-- Drop any Atlantis modules already loaded from another config on RTP (mixed installs).
for name in pairs(package.loaded) do
  if name:match("^configs%.hydra%.atlantis")
    or name == "configs.hydra.lib.make_hydra"
    or name:match("^configs%.hydra%.atlantis%.tests") then
    package.loaded[name] = nil
  end
end

-- nvim-hydra is not on RTP in headless CI; stub enough for `require("configs.hydra.lib.make_hydra")` at load time.
package.preload["hydra"] = function()
  return function(_)
    return {
      activate = function() end,
      hint = { close = function() end, show = function() end },
      __hint_window_hidden = false,
    }
  end
end

local plenary_dir = os.getenv("PLENARY_DIR")
if not plenary_dir or vim.fn.isdirectory(plenary_dir) == 0 then
  plenary_dir = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
end
if vim.fn.isdirectory(plenary_dir) == 0 then
  local fallback = vim.fn.tempname() .. "_plenary.nvim"
  vim.fn.system({ "git", "clone", "--depth", "1", "https://github.com/nvim-lua/plenary.nvim", fallback })
  plenary_dir = fallback
end

vim.opt.rtp:append(plenary_dir)
vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")
