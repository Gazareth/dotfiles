local build_node_info = require("configs.hydra.atlantis.treesitter.common.node_info").build_node_info
local parse_parameter = require("configs.hydra.atlantis.treesitter.probes.parameter").parse_parameter
local common_actions = require("configs.hydra.atlantis.ops.common")

local M = {}

-- Parameter state payload
function M.resolve_state(ctx)
  local parsed = type(ctx) == "table" and ctx.parsed or nil
  local node_info = type(ctx) == "table" and ctx.node_info or nil

  local latest_node_info = build_node_info({
    bufnr = node_info and node_info.bufnr or 0,
  })
  local active_node_info = latest_node_info or node_info

  local candidate = parsed
  if type(candidate) ~= "table" or type(candidate.parameter_nodes) ~= "table" then
    candidate = parse_parameter(active_node_info)
  end

  local parameter_targets = type(candidate.targets) == "table" and (candidate.targets.parameters or {}) or {}
  local current_index = candidate.parameter_index
  local parameter_count = #(candidate.parameter_nodes or {})

  if parameter_count > 0 and type(current_index) ~= "number" then
    current_index = 1
  end

  return {
    parsed = candidate,
    node_info = active_node_info,
    parameter_targets = parameter_targets,
    current_index = current_index,
    parameter_count = parameter_count,
  }
end

-- Cursor target jump
function M.jump_to_target(target)
  return common_actions.jump_to_target(target)
end

-- Current parameter target
function M.current_target(state)
  return state.parameter_targets[state.current_index]
end

-- Previous parameter target
function M.previous_target(state)
  if type(state.current_index) ~= "number" then
    return nil
  end

  return state.parameter_targets[state.current_index - 1]
end

-- Next parameter target
function M.next_target(state)
  if type(state.current_index) ~= "number" then
    return nil
  end

  return state.parameter_targets[state.current_index + 1]
end

-- Parameter labels for picker
function M.build_labels(targets)
  local labels = {}
  for index, target in ipairs(targets or {}) do
    labels[index] = tostring(index) .. ": " .. tostring(target.name or ("parameter " .. tostring(index)))
  end

  return labels
end

-- Textobjects swap module
local function load_textobjects_swap()
  local ok, swap = pcall(require, "nvim-treesitter.textobjects.swap")
  if not ok or type(swap) ~= "table" then
    return nil
  end

  return swap
end

-- Single parameter swap step
local function swap_parameter_step(direction)
  local swap = load_textobjects_swap()
  if not swap then
    vim.notify("Swap with parameter needs nvim-treesitter-textobjects swap", vim.log.levels.WARN)
    return false
  end

  local query = "@parameter.inner"
  local ok = false

  if direction == "next" and type(swap.swap_next) == "function" then
    ok = pcall(swap.swap_next, query)
  elseif direction == "previous" and type(swap.swap_previous) == "function" then
    ok = pcall(swap.swap_previous, query)
  end

  if not ok then
    vim.notify("Swap with parameter is unavailable", vim.log.levels.INFO)
    return false
  end

  return true
end

-- Swap from current index to target index
function M.swap_with_target_index(state, target_index)
  local current_index = state.current_index
  if type(current_index) ~= "number" or type(target_index) ~= "number" or current_index == target_index then
    vim.notify("Swap with parameter is unavailable", vim.log.levels.INFO)
    return false
  end

  local current_target = M.current_target(state)
  if not current_target then
    vim.notify("Swap with parameter is unavailable", vim.log.levels.INFO)
    return false
  end

  M.jump_to_target(current_target)()

  local step_count = math.abs(target_index - current_index)
  local direction = target_index > current_index and "next" or "previous"

  for _ = 1, step_count do
    if not swap_parameter_step(direction) then
      return false
    end
  end

  return true
end

return M
