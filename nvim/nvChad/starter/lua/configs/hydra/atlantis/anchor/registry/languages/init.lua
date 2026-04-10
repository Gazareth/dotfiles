local core = require("configs.hydra.atlantis.anchor.registry.languages.core")
local common = require("configs.hydra.atlantis.anchor.registry.languages.common")
local resolve_atlantis_mapping = require("configs.hydra.atlantis.anchor.probe.resolver").resolve

-- Built-in language tables
local base_languages = {
  lua = require("configs.hydra.atlantis.anchor.registry.languages.lua"),
}

local M = {}

-- Pass language tables into Atlantis resolver
function M.resolve(node_info, opts)
  opts = opts or {}

  return resolve_atlantis_mapping(node_info, {
    safe_languages = opts.safe_languages,
    user_languages = opts.languages,
    base_languages = base_languages,
    core = core,
    common = common,
    language = opts.language,
  })
end

return M
