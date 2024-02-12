local M = {}

-- Dashboard/Settings shortcuts
M.switch_window = function(command)
    return function()
      vim.cmd("wincmd " .. command)
      local newFileType = vim.bo.filetype
      if newFileType == "NvimTree" then
        vim.cmd("wincmd " .. command)
      end
    end
  end
  
M.current_file_dir = function()
    return vim.fn.expand "%:p:h"
end

M.explore_current_file_dir = function()
    if vim.g.is_windows then
        local escaped_file_path = current_file_dir():gsub("\\", "\\\\")
        local command = '!"explorer.exe \'' .. escaped_file_path .. "'\""
        vim.cmd(command)
    else
        vim.cmd("open " .. current_file_dir())
    end
end

M.return_to_dashboard = function(set_cd)
    return function()
        vim.cmd "tabonly | enew | BufOnly"
        vim.cmd "Alpha"
        if set_cd then
        local current_type = vim.bo.filetype
        if current_type ~= "alpha" and #current_type ~= 0 then
            vim.cmd "CdHome"
        end
        end
        -- Exit current project
        require("projections.switcher"):set_current()
    end
end

return M
