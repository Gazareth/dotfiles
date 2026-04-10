local M = {}

function M.build(runtime_ctx)
  local parsed = type(runtime_ctx) == "table" and runtime_ctx.parsed_anchor or nil
  local metrics = type(parsed) == "table" and parsed.metrics or nil
  local n = 0
  if type(metrics) == "table" and type(metrics.parameter_count) == "number" then
    n = metrics.parameter_count
  end

  return function(label, _action_name)
    if type(label) ~= "string" then
      return label
    end
    return string.format("%s [%d]", label, n)
  end
end

return M
