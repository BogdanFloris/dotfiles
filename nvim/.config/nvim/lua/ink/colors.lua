-- lua/ink/colors.lua
-- The room's palette (gruvbox soft) and the highlight groups Ink draws with.

local c = {
	bg = "#32302f",
	fg = "#ebdbb2",
	bright = "#fbf1c7",
	dim = "#7c6f64",
	faint = "#665c54",
	yellow = "#fabd2f",
	blue = "#83a598",
	aqua = "#8ec07c",
}

require("gruvbox").setup({
	inverse = true,
	contrast = "soft",
	overrides = {
		InkDim = { fg = c.dim },
		InkFaint = { fg = c.faint },
		InkMargin = { fg = c.dim, bg = c.bg },
		InkText = { fg = c.fg },
		InkTableHead = { fg = c.bright, bold = true },
		InkBold = { fg = c.bright, bold = true },
		InkCode = { fg = c.aqua },
		InkLink = { fg = c.blue, underline = true },
		-- Hides smoothscroll's "<<<" on a partly scrolled first line.
		NonText = { fg = c.bg },
		["@markup.heading"] = { fg = c.yellow, bold = true },
		["@markup.strong"] = { fg = c.bright, bold = true },
		["@markup.link.label"] = { fg = c.blue, underline = true },
		["@punctuation.special.markdown"] = { fg = c.faint },
		-- Inline code as plain colored text, without render-markdown's background patches.
		["@markup.raw.markdown_inline"] = { fg = c.aqua },
		RenderMarkdownCodeInline = { fg = c.aqua },
		RenderMarkdownBullet = { fg = c.dim },
	},
})

return c
