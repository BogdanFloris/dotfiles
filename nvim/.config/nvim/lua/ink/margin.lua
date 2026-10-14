-- lua/ink/margin.lua
-- Heading markers hang in a 4-column left margin, iA Writer style (the window's statuscolumn).

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

function M.column()
	local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
	local marks = vim.v.virtnum == 0 and (marks_by_buf[buf] or {})[vim.v.lnum]
	if not marks then
		return "%#InkMargin#    "
	end
	return "%#InkMargin#" .. (#marks <= 3 and string.format("%3s ", marks) or ("#" .. #marks .. "  "))
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
