-- Modify section: builds the node-specific menu spec via the renderer
local renderer = require("configs.hydra.atlantis.menu.renderer")

-- Produce menu spec for the anchor node at cursor from pre-built render spec
return function(runtime_ctx)
  return renderer.build_from_context(runtime_ctx)
end
