local create = require("configs.hydra.atlantis_nouveau.ops.actions.create")

-- Ordered list of create groups. The first group whose token appears in
-- result.available_actions wins (elseif semantics — only one fires per node).
-- Each item may carry an optional `when(result)` guard for finer conditions.
return {
  { token = "prepend_append_statement", items = {
      { key="I", icon="󰏪", label="Create before", fn=create.statement.before },
      { key="O", icon="󰏬", label="Create after",  fn=create.statement.after  },
  }},
  { token = "prepend_append_item", items = {
      { key="I", icon="󰏪", label="Add before", fn=create.list_item.before,
        when = function(r) return r.navigation and r.navigation.prev_sibling end },
      { key="O", icon="󰏬", label="Add after",  fn=create.list_item.after  },
  }},
  { token = "prepend_append_list", items = {
      { key="I", icon="󰏪", label="Add first", fn=create.list.first },
      { key="O", icon="󰏬", label="Add last",  fn=create.list.last  },
  }},
}
