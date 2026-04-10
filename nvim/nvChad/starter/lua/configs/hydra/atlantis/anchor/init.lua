local build = require("configs.hydra.atlantis.anchor.build")

local M = {}

-- Delegate anchor build steps through the build entry module
function M.build(depth_or_opts)
  if type(depth_or_opts) == "string" then
    return build.build({
      depth_mode = depth_or_opts,
    })
  end

  return build.build(depth_or_opts)
end

return M
