local M = {}
local atlantis_constants = require("configs.hydra.treesitter.lib.atlantis.constants")

local nt = atlantis_constants.node_tiers
local nk = atlantis_constants.node_kinds
local aid = atlantis_constants.action_ids

-- Shared fallback mappings
M.mappings = {
  identifier = {
    node_tier = nt.chambers,
    node_kind = nk.identifier,
    actionable = true,
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
}

-- Shared action rules
M.action_matrix = {
  _default = { aid.inspect },
  [nt.settlement] = {
    _default = { aid.jump },
    [nk.declaration] = {
      aid.change_name,
      aid.view_call_hierarchy,
      aid.jump,
      aid.yank,
      aid.delete,
    },
  },
  [nt.grove] = {
    [nk.collection] = { aid.jump, aid.yank },
  },
  [nt.cluster] = {
    [nk.control_frame] = { aid.jump, aid.yank },
  },
  [nt.habitat] = {
    [nk.statement] = { aid.change, aid.yank, aid.delete },
    [nk.assignment] = { aid.change, aid.yank, aid.delete },
    [nk.call] = { aid.change, aid.yank, aid.delete },
  },
  [nt.chambers] = {
    [nk.identifier] = { aid.change, aid.yank },
    [nk.property] = { aid.change, aid.yank },
    [nk.string] = { aid.change, aid.yank },
  },
  [nt.coral] = {
    [nk.keyword] = { aid.inspect, aid.jump_parent },
    [nk.operator] = { aid.inspect },
  },
  [nt.reef] = {
    [nk.comment] = { aid.change, aid.yank, aid.delete },
    [nk.whitespace] = { aid.inspect },
    [nk.delimiter] = { aid.inspect },
  },
}

return M
