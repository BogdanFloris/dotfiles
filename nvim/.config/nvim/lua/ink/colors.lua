-- lua/ink/colors.lua
-- Ink draws with your current colorscheme. Its own groups are derived from it, so nothing gets
-- overridden and a colorscheme change carries over.

local util = require("ink.util")

local function get(name)
	return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local function apply()
	local normal, comment, linenr = get("Normal"), get("Comment"), get("LineNr")
	vim.api.nvim_set_hl(0, "InkDim", { fg = comment.fg })
	vim.api.nvim_set_hl(0, "InkFaint", { fg = linenr.fg })
	vim.api.nvim_set_hl(0, "InkMargin", { fg = linenr.fg, bg = normal.bg })
	-- Hides smoothscroll's "<<<" inside the room only (applied through winhighlight in ink.room).
	vim.api.nvim_set_hl(0, "InkHidden", { fg = normal.bg })
	vim.api.nvim_set_hl(0, "InkText", { link = "Normal" })
	vim.api.nvim_set_hl(0, "InkTableHead", { fg = normal.fg, bold = true })
	vim.api.nvim_set_hl(0, "InkBold", { link = "@markup.strong" })
	vim.api.nvim_set_hl(0, "InkCode", { link = "@markup.raw.markdown_inline" })
	vim.api.nvim_set_hl(0, "InkLink", { link = "@markup.link.label" })
end

apply()
vim.api.nvim_create_autocmd("ColorScheme", { group = util.group, callback = apply })
