-- Parsed function payload: prefer declared function name.
local M = {}

function M.try(parsed, _node_info)
  if type(parsed) ~= "table" or type(parsed.function_name) ~= "string" then
    return nil
  end
  local function_name = vim.trim(parsed.function_name)
  if function_name ~= "" and function_name ~= "anonymous" then
    return function_name
  end
  return nil
end

return M
