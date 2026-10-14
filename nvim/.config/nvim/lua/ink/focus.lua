-- lua/ink/focus.lua
-- Dims everything outside the paragraph under the cursor.

local util = require("ink.util")

local ns = vim.api.nvim_create_namespace("ink_focus")

local function focus()
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	if not util.is_text(buf) then
		return
	end
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local function blank(i)
		return lines[i]:match("^%s*$") ~= nil
	end
	local first = vim.api.nvim_win_get_cursor(0)[1]
	local last = first
	if not blank(first) then
		while first > 1 and not blank(first - 1) do
			first = first - 1
		end
		while last < #lines and not blank(last + 1) do
			last = last + 1
		end
	end
	local function dim(from, to)
		vim.api.nvim_buf_set_extmark(buf, ns, from - 1, 0, {
			end_row = to - 1,
			end_col = #lines[to],
			hl_group = "InkDim",
			priority = 10000,
		})
	end
	if first > 1 then
		dim(1, first - 1)
	end
	if last < #lines then
		dim(last + 1, #lines)
	end
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI" }, {
	group = util.group,
	callback = focus,
})
