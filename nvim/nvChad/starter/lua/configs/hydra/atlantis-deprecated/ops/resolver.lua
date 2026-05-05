local scoped = require("configs.hydra.atlantis-deprecated.lib.resolver")

local M = {}

local root_prefix = "configs.hydra.atlantis-deprecated.ops.actions"

function M.resolve(action_name, node_kind)
  return scoped.resolve(root_prefix, action_name, node_kind)
end

function M.build(action_name, node_kind, ctx)
  local builder = M.resolve(action_name, node_kind)
  if type(builder) ~= "function" then
    return nil
  end

  return builder(ctx or {}, node_kind)
end

function M.builder(action_name)
  return function(ctx, node_kind)
    return M.build(action_name, node_kind, ctx)
  end
end

setmetatable(M, {
  __index = function(_, key)
    if type(key) ~= "string" or key == "" then
      return nil
    end

    return M.builder(key)
  end,
})

return M
