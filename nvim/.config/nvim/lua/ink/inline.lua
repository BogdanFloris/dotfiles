-- lua/ink/inline.lua
-- Inline syntax (emphasis, strikethrough, code spans, links) stays hidden except in the element under
-- the cursor, which shows raw so it can be edited. Treesitter's conceal can't be lifted for a single
-- element, so the markdown_inline query loses its empty conceals and Ink conceals with extmarks.

local util = require("ink.util")

local ns = vim.api.nvim_create_namespace("ink_inline")

-- The children each element hides, matching what the stock query concealed.
local link = { ["["] = true, ["]"] = true, ["("] = true, [")"] = true, link_destination = true }
local hide = {
	emphasis = { emphasis_delimiter = true },
	strong_emphasis = { emphasis_delimiter = true },
	strikethrough = { emphasis_delimiter = true },
	code_span = { code_span_delimiter = true },
	inline_link = link,
	image = vim.tbl_extend("force", link, { ["!"] = true }),
	full_reference_link = { ["["] = true, ["]"] = true, link_label = true },
	collapsed_reference_link = { ["["] = true, ["]"] = true },
	shortcut_link = { ["["] = true, ["]"] = true },
}
local ok, query = pcall(
	vim.treesitter.query.parse,
	"markdown_inline",
	"[" .. table.concat(vim.tbl_map(function(t) return "(" .. t .. ")" end, vim.tbl_keys(hide)), " ") .. "] @el"
)
if not ok then
	return -- no markdown_inline parser: keep the stock conceal
end

-- Entities keep their replacement characters; only the empty conceals (markers, link parts) go.
do
	local src = {}
	for _, file in ipairs(vim.treesitter.query.get_files("markdown_inline", "highlights")) do
		src[#src + 1] = table.concat(vim.fn.readfile(file), "\n")
	end
	local text = table.concat(src, "\n"):gsub('%(#set! conceal ""%)', "")
	vim.treesitter.query.set("markdown_inline", "highlights", text)
end

-- While typing, the cursor sits just past the element it is finishing, so the end counts in insert.
local function contains(node, row, col, insert)
	local sr, sc, er, ec = node:range()
	if row < sr or row > er or (row == sr and col < sc) then
		return false
	end
	return row < er or col < ec or (insert and col == ec)
end

local function render()
	local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	if not util.is_text(buf) then
		return
	end
	local ok, parser = pcall(vim.treesitter.get_parser, buf)
	if not ok or not parser then
		return
	end
	-- A screen beyond each edge of the view, so scrolling never shows unconcealed syntax.
	local height = vim.api.nvim_win_get_height(win)
	local top = math.max(vim.fn.line("w0", win) - 1 - height, 0)
	local bot = vim.fn.line("w$", win) + height
	parser:parse({ top, bot })
	local cursor = vim.api.nvim_win_get_cursor(win)
	local row, col = cursor[1] - 1, cursor[2]
	local insert = vim.api.nvim_get_mode().mode:match("^[iR]") ~= nil
	parser:for_each_tree(function(tree, ltree)
		local root = tree:root()
		local sr, _, er = root:range()
		if ltree:lang() ~= "markdown_inline" or er < top or sr >= bot then
			return
		end
		for _, node in query:iter_captures(root, buf, top, bot) do
			if not contains(node, row, col, insert) then
				local parts = hide[node:type()]
				for child in node:iter_children() do
					if parts[child:type()] then
						local csr, csc, cer, cec = child:range()
						vim.api.nvim_buf_set_extmark(buf, ns, csr, csc, { end_row = cer, end_col = cec, conceal = "" })
					end
				end
			end
		end
	end)
end

vim.api.nvim_create_autocmd(
	{ "BufWinEnter", "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI", "WinScrolled", "ModeChanged" },
	{ group = util.group, callback = render }
)
