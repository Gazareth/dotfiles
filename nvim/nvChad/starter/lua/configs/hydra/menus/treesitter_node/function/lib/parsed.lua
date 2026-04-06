local M = {}

-- Read metrics from parsed data with a safe fallback.
function M.get_metrics(parsed)
  if type(parsed) ~= "table" or type(parsed.metrics) ~= "table" then
    return {}
  end

  return parsed.metrics
end

-- Read jump targets from parsed data with a safe fallback.
function M.get_targets(parsed)
  if type(parsed) ~= "table" or type(parsed.targets) ~= "table" then
    return {}
  end

  return parsed.targets
end

-- Function menu title
function M.build_title(parsed)
  local name = ""
  if type(parsed) == "table" and type(parsed.function_name) == "string" then
    name = vim.trim(parsed.function_name)
  end

  if name == "" then
    return "Function"
  end

  return 'Function "' .. name .. '"'
end

-- Read a metric value with a fallback.
function M.value_or(metrics, key, fallback)
  local value = metrics[key]
  if value == nil then
    return fallback
  end

  return value
end

return M
