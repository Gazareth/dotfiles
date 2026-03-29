local M = {}

local function get_module_path(item)
  if type(item.module) ~= "string" then
    return nil
  end

  if type(item.submodule) == "string" and item.submodule ~= "" then
    return item.module .. "." .. item.submodule
  end

  return item.module
end

local function run_module_function(item)
  local module_path = get_module_path(item)
  if module_path == nil or type(item.fn) ~= "string" then
    return false
  end

  local ok, mod = pcall(require, module_path)
  if not ok then
    vim.notify("Failed to load module: " .. module_path, vim.log.levels.ERROR)
    return true
  end

  local fn = mod[item.fn]
  if type(fn) ~= "function" then
    vim.notify("Menu item is missing function: " .. item.fn, vim.log.levels.ERROR)
    return true
  end

  fn(item)
  return true
end

function M.execute(item)
  if type(item.action) == "function" then
    item.action(item)
    return
  end

  if type(item.action) == "string" and item.action ~= "" then
    local ok, err = pcall(vim.cmd, item.action)
    if not ok then
      vim.notify("Failed to run command: " .. item.action .. " (" .. tostring(err) .. ")", vim.log.levels.ERROR)
    end
    return
  end

  if run_module_function(item) then
    return
  end

  if type(item._menu) == "table" and type(item._menu.resolve) == "function" then
    item._menu.resolve(item)
  end
end

return M
