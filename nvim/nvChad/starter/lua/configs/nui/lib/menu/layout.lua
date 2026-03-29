local str = require("configs.nui.lib.string")
local unpack_values = table.unpack or unpack

local M = {}

local function max_or_zero(values)
	if #values == 0 then
		return 0
	end

	return math.max(unpack_values(values))
end

-- Pad text on the left to a target display width.
function M.pad_left(value, width)
	local text = value or ""
	local missing = width - str.display_width(text)
	if missing > 0 then
		return string.rep(" ", missing) .. text
	end

	return text
end

-- Pad text on the right to a target display width.
function M.pad_right(value, width)
	local text = value or ""
	local missing = width - str.display_width(text)
	if missing > 0 then
		return text .. string.rep(" ", missing)
	end

	return text
end

-- Center text inside a fixed display width.
function M.pad_center(value, width)
	local text = value or ""
	local missing = width - str.display_width(text)
	if missing > 0 then
		local left = math.floor(missing / 2)
		local right = missing - left
		return string.rep(" ", left) .. text .. string.rep(" ", right)
	end

	return text
end

local function create_section_layout(list, prompt, list_count)
	local title = list.title or prompt or "Actions"
	if list_count == 1 and prompt then
		title = prompt
	end

	local line_widths = vim.tbl_map(function(line)
		return str.display_width(line.text)
	end, list.lines or {})

	local max_label_len = max_or_zero(line_widths)
	local title_width = str.display_width(" " .. title .. " ")

	return {
		title = title,
		size = {
			width = math.max(max_label_len + 2, title_width + 2, 4),
			height = math.max(#(list.lines or {}), 1) + 2,
		},
		popup = {
			border = {
				style = "rounded",
				text = {
					top = " " .. title .. " ",
					top_align = "center",
				},
			},
			win_options = {
				cursorline = false,
			},
		},
	}
end

-- Build popup layout options from rendered lists and prompt.
function M.create_menu_layout(lists, prompt)
	local sections = {}
	local total_width = 0
	local max_height = 1

	for _, list in ipairs(lists or {}) do
		local section = create_section_layout(list, prompt, #(lists or {}))
		sections[#sections + 1] = section
		total_width = total_width + section.size.width
		max_height = math.max(max_height, section.size.height)
	end

	if #sections == 0 then
		sections[1] = create_section_layout({ lines = {}, title = prompt }, prompt, 1)
		total_width = sections[1].size.width
		max_height = sections[1].size.height
	end

	return {
		layout = {
			relative = "editor",
			position = "50%",
			size = {
				width = total_width,
				height = max_height,
			},
		},
		sections = sections,
	}
end

return M
