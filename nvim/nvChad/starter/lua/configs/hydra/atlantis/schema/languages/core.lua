-- Shared fallback mappings across all languages
local constants = require("configs.hydra.atlantis.schema.constants")

local nt = constants.node_tiers
local nk = constants.node_kinds

return {
  mappings = {
    identifier = {
      node_tier = nt.chambers,
      node_kind = nk.identifier,
      actionable = true,
      -- Identifiers that name a declaration are not meaningful anchors;
      -- the declaration itself is. Parent types listed here suppress actionability.
      non_actionable_parent_types = {
        function_declaration = true,
        local_function       = true,
        function_definition  = true,
        method_definition    = true,
      },
    },
    string = {
      node_tier = nt.chambers,
      node_kind = nk.string,
      actionable = true,
    },
    comment = {
      node_tier = nt.reef,
      node_kind = nk.comment,
      actionable = true,
    },
  },
}
