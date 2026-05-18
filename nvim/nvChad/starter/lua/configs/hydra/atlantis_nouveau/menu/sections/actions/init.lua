local subsections = "configs.hydra.atlantis_nouveau.menu.sections.actions.subsections"

local create_sub = require(subsections .. ".create")
local modify_sub = require(subsections .. ".modify")
local tools_sub  = require(subsections .. ".tools")

local M = {}

function M.build(result)
  -- ── Context ───────────────────────────────────────────────────────────────
  -- Build a shared context table once and pass it to both subsections so they
  -- don't each repeat these lookups.

  local node_type = result.node and result.node.node and result.node.node.type

  local avail = {}
  for _, a in ipairs(result.available_actions or {}) do avail[a] = true end

  local ctx = {
    node_type    = node_type,
    nav          = result.navigation,
    avail        = avail,
    lsp_attached = #vim.lsp.get_clients({ bufnr = result.bufnr, method = "textDocument/codeAction" }) > 0,
  }

  -- ── Subsections ───────────────────────────────────────────────────────────

  local create_items = create_sub.build(result, ctx)
  local modify_items = modify_sub.build(result, ctx)
  local tools_items  = tools_sub.build(result, ctx)

  if #create_items == 0 and #modify_items == 0 and #tools_items == 0 then return nil end

  -- ── Assemble ──────────────────────────────────────────────────────────────
  -- Headings are only emitted when the corresponding subsection is non-empty.

  local items = {}
  local function section(heading, section_items)
    if #section_items == 0 then return end
    items[#items + 1] = { heading = heading }
    for _, v in ipairs(section_items) do items[#items + 1] = v end
  end

  section("Create", create_items)
  section("Modify", modify_items)
  section("Tools",  tools_items)

  return { title = "Actions", items = items }
end

return M
