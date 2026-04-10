-- Parameter sibling navigation and swap capabilities
local M = {}

-- Bind nested adapter section method as closure for capability lookup
local function bind_nested_method(adapter, section_name, method_name)
  if type(adapter) ~= "table" or type(section_name) ~= "string" or type(method_name) ~= "string" then
    return nil
  end

  return function(...)
    local section = adapter[section_name]
    local method = type(section) == "table" and section[method_name] or nil
    if type(method) ~= "function" then
      return nil
    end

    return method(section, ...)
  end
end

-- Build parameter sibling action callbacks for capability system
function M.build(adapter)
  return {
    actions = {
      jump_next = bind_nested_method(adapter, "sibling", "jump_next"),
      jump_previous = bind_nested_method(adapter, "sibling", "jump_previous"),
      swap_next = bind_nested_method(adapter, "sibling", "swap_next"),
      swap_previous = bind_nested_method(adapter, "sibling", "swap_previous"),
      jump_prompt = bind_nested_method(adapter, "sibling", "jump_prompt"),
      swap_prompt = bind_nested_method(adapter, "sibling", "swap_prompt"),
    },
    availability = {
      has_previous = bind_nested_method(adapter, "sibling", "has_previous"),
      has_next = bind_nested_method(adapter, "sibling", "has_next"),
      has_swappable = bind_nested_method(adapter, "sibling", "has_swappable"),
    },
  }
end

return M
