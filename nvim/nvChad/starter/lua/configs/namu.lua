local function calculate_editor_center_position(width, height)
  local columns = vim.api.nvim_get_option_value("columns", {})
  local lines = vim.api.nvim_get_option_value("lines", {})
  local desired_col = math.floor((columns - width) / 2)
  local desired_row = math.floor((lines - height) / 2)
  return columns - desired_col, desired_row
end

local function normalize_menu_items(raw_items, keys)
  local normalized = {}
  for _, item in ipairs(raw_items) do
    local entry = {}
    for index, key in ipairs(keys) do
      entry[key] = item[index]
    end
    normalized[#normalized + 1] = entry
  end
  return normalized
end

local function open_fastaction_menu(menu_items, prompt_text)
  local fastaction = require("fastaction")

  local max_label_len = 0
  for _, item in ipairs(menu_items) do
    max_label_len = math.max(max_label_len, vim.fn.strdisplaywidth(item.label or ""))
  end

  local title_width = vim.fn.strdisplaywidth(" " .. prompt_text)
  local popup_width = math.max(max_label_len + 1, title_width) + 1
  local popup_height = #menu_items + 2
  local x_offset, y_offset = calculate_editor_center_position(popup_width, popup_height)

  fastaction.select(menu_items, {
    prompt = prompt_text,
    format_item = function(item)
      return item.label
    end,
    relative = "editor",
    x_offset = x_offset,
    y_offset = y_offset,
    border = "rounded",
  }, function(choice)
    if not choice then
      return
    end

    if type(choice.action) == "function" then
      choice.action(choice)
      return
    end

    if choice.module and choice.fn then
      local ok, mod = pcall(require, "namu." .. choice.module)
      if not ok then
        vim.notify("Failed to load Namu module: namu." .. choice.module, vim.log.levels.ERROR)
        return
      end
      local fn = mod[choice.fn]
      if type(fn) ~= "function" then
        vim.notify("Namu menu item is missing function: " .. choice.fn, vim.log.levels.ERROR)
        return
      end
      fn()
    end
  end)
end

local function open_namu_menu()
  local raw_menu_items = {
    { "Diagnostics: Buffer",    "namu_diagnostics",   "show_current_diagnostics" },
    { "Diagnostics: Open",      "namu_diagnostics",   "show_buffer_diagnostics" },
    { "Diagnostics: Workspace", "namu_diagnostics",   "show_workspace_diagnostics" },
    { "Symbols: Buffer",        "namu_symbols",       "show" },
    { "Calls: Incoming",        "namu_callhierarchy", "show_incoming_calls" },
    { "Calls: Outgoing",        "namu_callhierarchy", "show_outgoing_calls" },
    { "Calls: Both",            "namu_callhierarchy", "show_both_calls" },
  }
  local menu_items = normalize_menu_items(raw_menu_items, { "label", "module", "fn" })

  open_fastaction_menu(menu_items, "Namu Features")
end

vim.keymap.set("n", "<leader>nm", open_namu_menu, { desc = "Namu Fast Menu" })
