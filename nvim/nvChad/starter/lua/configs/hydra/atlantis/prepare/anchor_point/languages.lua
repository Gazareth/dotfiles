-- Resolve semantic language mappings from table-only language registries
local languages = require("configs.hydra.atlantis.schema.languages")
local resolve_atlantis_mapping = require("configs.hydra.atlantis.prepare.anchor_point.probe.resolver").resolve

local M = {}

-- Pass language tables into Atlantis resolver
function M.resolve(node_info, opts)
  opts = opts or {}

  return resolve_atlantis_mapping(node_info, {
    safe_languages = opts.safe_languages,
    user_languages = opts.languages,
    base_languages = languages.base,
    core = languages.core,
    common = languages.common,
    language = opts.language,
  })
end

return M
