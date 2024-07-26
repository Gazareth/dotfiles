-- Courtesy of https://www.reddit.com/r/neovim/comments/reovwj/comment/ht88eug/?utm_source=reddit&utm_medium=web2x&context=3
local M = {}

vim.g.is_windows = vim.loop.os_uname().version:match('Windows')

local path_sep = vim.g.is_windows and '\\' or '/'

-----------------------------------------------------------
-- Concatenates given paths with correct separator.
-- @param: var args of string paths to joon.
-----------------------------------------------------------
function M.join_paths(...)
    local result = table.concat({ ... }, path_sep)
    return result
end

-- Require all other `.lua` files in the same directory
local _base_lua_path = M.join_paths(vim.fn.stdpath('config'), 'lua')

-----------------------------------------------------------
-- Loads all modules from the given package.
-- @param package: name of the package in lua folder.
-----------------------------------------------------------
function M.glob_require(package)
    local found_files = {}
    local glob_path = M.join_paths(
      _base_lua_path,
      package,
      '*.lua'
    )

    for _, path in pairs(vim.split(vim.fn.glob(glob_path), '\n')) do
        -- convert absolute filename to relative
        -- ~/.config/nvim/lua/<package>/<module>.lua => <package>/foo
        local relfilename = path:gsub(_base_lua_path .. "\\", ""):gsub(".lua", "")
        local basename = vim.fs.basename(relfilename)
        local module_name = relfilename:gsub("\\", ".")

        -- skip `init` and files starting with underscore.
        if (basename ~= 'init' and basename:sub(1, 1) ~= '_') then
            vim.tbl_deep_extend("error", found_files, require(module_name))
        end
    end

    return found_files
end

return M
