local M = {}

local function calculate_editor_center_position(width, height)
  local columns = vim.api.nvim_get_option_value("columns", {})
  local lines = vim.api.nvim_get_option_value("lines", {})
  local desired_col = math.floor((columns - width) / 2)
  local desired_row = math.floor((lines - height) / 2)
  return columns - desired_col, desired_row
end

local function open_menu(menu)
  local fastaction = require("fastaction")

  local max_label_len = 0
  for _, item in ipairs(menu.items or {}) do
    max_label_len = math.max(max_label_len, vim.fn.strdisplaywidth(item.label or ""))
  end

  local prompt = menu.prompt or "Actions"
  local title_width = vim.fn.strdisplaywidth(" " .. prompt)
  local popup_width = math.max(max_label_len + 1, title_width) + 1
  local popup_height = #(menu.items or {}) + 2
  local x_offset, y_offset = calculate_editor_center_position(popup_width, popup_height)

  fastaction.select(menu.items or {}, {
    prompt = prompt,
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

    if type(menu.resolve) == "function" then
      menu.resolve(choice)
    end
  end)
end

function M.setup()
  local specs = require("configs.fastactions.action_menus")
  local menus = specs.menus or {}

  for _, map in ipairs(specs.keymaps or {}) do
    if map.menu and menus[map.menu] then
      vim.keymap.set(map.mode, map.lhs, function()
        open_menu(menus[map.menu])
      end, { desc = map.desc })
    elseif map.rhs then
      vim.keymap.set(map.mode, map.lhs, map.rhs, { desc = map.desc })
    end
  end
end

return M
