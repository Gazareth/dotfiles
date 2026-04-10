-- Core parameter actions: rename and remove
local M = {}

-- Bind adapter method as closure for capability lookup
local function bind_method(adapter, method_name)
  if type(adapter) ~= "table" or type(method_name) ~= "string" then
    return nil
  end

  return function(...)
    local method = adapter[method_name]
    if type(method) ~= "function" then
      return nil
    end

    return method(adapter, ...)
  end
end

-- Build core parameter action callbacks for capability system
function M.build(adapter)
  return {
    actions = {
      rename = bind_method(adapter, "rename"),
      remove = bind_method(adapter, "remove"),
    },
  }
end

return M
