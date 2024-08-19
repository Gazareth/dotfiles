local glob_require = require("functions.globRequire").glob_require

local mappings = glob_require("mappings")

for category, category_maps in pairs(mappings) do
  for mode, maps in pairs(category_maps) do
    for key, val in pairs(maps) do
      if category ~= "disabled" then
        vim.keymap.set(mode, key, val[1], { desc = category .. " " .. val[2] })
      else
        vim.keymap.del(mode, key)
      end
    end
  end
end
