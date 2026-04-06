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
  -- Title metrics segment
  local function build_metrics_segment(value)
    local metrics = M.get_metrics(value)
    local targets = M.get_targets(value)
    local line_span = M.value_or(metrics, "line_span", "?")
    local parameter_count = M.value_or(metrics, "parameter_count", 0)
    local assignment_count = #(targets.assignments or {})

    return string.format(
      "{%s lines; %s parameters; %s assignments}",
      tostring(line_span),
      tostring(parameter_count),
      tostring(assignment_count)
    )
  end

  local name = ""
  if type(parsed) == "table" and type(parsed.function_name) == "string" then
    name = vim.trim(parsed.function_name)
  end

  local metrics_segment = build_metrics_segment(parsed)

  if name == "" then
    return "[Function] " .. metrics_segment
  end

  return "[Function] " .. name .. " " .. metrics_segment
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
