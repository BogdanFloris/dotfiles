-- lua/ink/margin.lua
-- The left margin (the window's statuscolumn): relative line numbers, and heading markers hanging
-- next to the text, iA Writer style.

local util = require("ink.util")

local M = {}

local marks_by_buf = {}
local query = vim.treesitter.query.parse("markdown", "(atx_heading) @heading")

local function scan(buf)
	local marks = {}
	local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
	if ok and parser then
		for _, node in query:iter_captures(parser:parse()[1]:root(), buf) do
			local row = node:start()
			marks[row + 1] = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]:match("^#+")
		end
	end
	marks_by_buf[buf] = marks
end

M.width = 8 -- number (3), space, heading marker (3), space

function M.column()
	if vim.v.virtnum ~= 0 then
		return "%#InkMargin#" .. string.rep(" ", M.width)
	end
	local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
	local marks = (marks_by_buf[buf] or {})[vim.v.lnum] or ""
	if #marks > 3 then
		marks = "#" .. #marks
	end
	local nr = vim.v.relnum == 0 and "%#InkCursorNr#" or "%#InkMargin#"
	return ("%s%3d %%#InkMargin#%3s "):format(nr, vim.v.relnum, marks)
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI" }, {
	group = util.group,
	callback = function(ev)
		if util.is_text(ev.buf) and vim.bo[ev.buf].filetype == "markdown" then
			scan(ev.buf)
		end
	end,
})

return M
