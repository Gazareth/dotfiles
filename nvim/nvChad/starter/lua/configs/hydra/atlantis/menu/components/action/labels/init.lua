local resolver = require("configs.hydra.atlantis.menu.components.action.labels.resolver")

local M = {}

local actions_with_label_builders = {
  "jump_to_parameter",
}

function M.build_overrides(runtime_ctx)
  local parsed = type(runtime_ctx) == "table" and runtime_ctx.parsed_anchor or nil
  local anchor_kind = type(parsed) == "table" and parsed.node_kind or nil

  local overrides = {}
  for _, action_name in ipairs(actions_with_label_builders) do
    local build = resolver.resolve(action_name, anchor_kind)
    if type(build) == "function" then
      local label_fn = build(runtime_ctx)
      if type(label_fn) == "function" then
        overrides[action_name] = label_fn
      end
    end
  end

  return overrides
end

return M
