
local glob_require = require("functions.globRequire").glob_require

local mappings = glob_require("mappings")

for _, section in pairs(mappings) do
  for mode, maps in pairs(section) do
    for key, val in pairs(maps) do
      vim.keymap.set(mode, key, val[1], { desc = val[2] })
    end
  end
end
