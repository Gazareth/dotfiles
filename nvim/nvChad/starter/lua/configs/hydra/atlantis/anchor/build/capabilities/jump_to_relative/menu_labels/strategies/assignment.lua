-- Parsed assignment payload: LHS only (never the RHS), same heuristics as text/condense fallback.
local condense = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels.condense")
local text = require("configs.hydra.atlantis.anchor.build.capabilities.jump_to_relative.menu_labels.text")
local supported_nodes = require("configs.hydra.atlantis.anchor.probe.treesitter.constants").supported_nodes
local nk = require("configs.hydra.atlantis.schema.constants").node_kinds

local M = {}

function M.try(parsed, node_info)
  if type(parsed) ~= "table" then
    return nil
  end

  local raw = type(parsed.text) == "string" and parsed.text or (node_info and node_info.text) or ""
  raw = vim.trim(raw:gsub("\n+", " "))
  local scrubbed = text.scrub_preview_text(raw, parsed, parsed.node_type)

  local has_targets = type(parsed.targets) == "table"
    and type(parsed.targets.left) == "table"
    and type(parsed.targets.left.name) == "string"
    and vim.trim(parsed.targets.left.name) ~= ""

  local nt = node_info and node_info.node_type or ""
  local expr_stmt_assignish = nt == "expression_statement"
    and scrubbed:find("=", 1, true)
    and not scrubbed:match("^%s*function%s")

  local looks_like_assign = parsed.node_kind == supported_nodes.assignment
    or parsed.semantic_kind == nk.assignment
    or has_targets
    or text.lhs_identifier_from_assignment_line(scrubbed) ~= nil
    or expr_stmt_assignish

  if not looks_like_assign then
    return nil
  end

  local compact = text.compact_code_snippet(scrubbed)
  local from_line = condense.condense_to_jump_name(compact, parsed.node_type)
  if type(from_line) ~= "string" then
    from_line = ""
  end

  if has_targets then
    local left_n = condense.condense_to_jump_name(vim.trim(parsed.targets.left.name), nil)
    if type(left_n) ~= "string" then
      left_n = ""
    end
    if from_line ~= "" and from_line:match("^[%a_][%w_]*$") then
      return from_line
    end
    if left_n ~= "" then
      return left_n
    end
  end

  if from_line ~= "" then
    return from_line
  end

  return nil
end

return M
