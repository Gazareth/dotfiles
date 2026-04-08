local M = {}
local title_builder = require("configs.hydra.atlantis.menu.nodes.common.title")

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

-- Function menu title using the shared title format
function M.build_title(parsed)
  local metrics = M.get_metrics(parsed)
  local targets = M.get_targets(parsed)
  local line_span = M.value_or(metrics, "line_span", "?")
  local parameter_count = M.value_or(metrics, "parameter_count", 0)
  local assignment_count = #(targets.assignments or {})

  local metric_parts = {
    tostring(line_span) .. " lines",
    tostring(parameter_count) .. " parameters",
    tostring(assignment_count) .. " assignments",
  }

  local name = ""
  if type(parsed) == "table" and type(parsed.function_name) == "string" then
    name = vim.trim(parsed.function_name)
  end

  return title_builder.build({
    semantic_kind = "declaration",
    node_type     = parsed and parsed.node_type,
    name          = name ~= "" and name or nil,
    metrics       = metric_parts,
  })
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
