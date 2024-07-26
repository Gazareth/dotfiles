
local glob_require = require("custom.functions.globRequire").glob_require

local mappings = glob_require("custom/mappings")

print(vim.inspect(mappings))

for _, section in pairs(mappings) do
  for mode, maps in pairs(section) do
    for key, val in pairs(maps) do
      vim.keymap.set(mode, key, val[1], val[2])
    end
  end
end
