local renderer = require("configs.hydra.atlantis.menu.renderer")
local render_spec = require("configs.hydra.atlantis.menu.render_spec")

return function(runtime_ctx)
  runtime_ctx.render_spec = render_spec.build(runtime_ctx)
  return renderer.build_from_context(runtime_ctx)
end
