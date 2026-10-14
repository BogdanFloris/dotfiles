-- lua/ink/init.lua
-- Ink, the writing room: Neovim in writing mode, in the current terminal. Loaded when INK_WRITING
-- is set (the `ink` script, or INK_WRITING=1 nvim file.md).

vim.env.INK_WRITING = nil

require("ink.colors")

-- quickfile redraws the raw file before the room opens, which flickers.
Snacks.config.quickfile.enabled = false

-- setup() replaces the config from plugins.lua, so its base options are repeated here.
-- Heading markers are concealed in the text and drawn in the left margin instead (ink.margin).
-- Tables are drawn by Ink itself (ink.tables), so render-markdown's renderer is off.
require("render-markdown").setup({
	render_modes = true,
	anti_conceal = { enabled = false },
	win_options = { concealcursor = { rendered = "nvic" } },
	heading = { sign = false, icons = { "" }, position = "inline", backgrounds = {} },
	link = { enabled = false },
	pipe_table = { enabled = false },
	code = { sign = false },
	on = {
		render = function(ctx)
			require("ink.room").rendered(ctx)
		end,
	},
})

vim.g.loaded_dropbar = true
vim.g.snacks_indent = false
vim.g.snacks_scope = false
vim.g.minicompletion_disable = true
vim.diagnostic.enable(false)
-- Zen is the room itself; toggling it off would quit (see on_close in ink.room).
vim.keymap.set({ "n", "t" }, "<leader>zm", "<Nop>")

vim.o.laststatus = 0
vim.o.showtabline = 0
vim.o.showmode = false
vim.o.showcmd = false
vim.o.ruler = true
vim.o.rulerformat = "%30(%=%#InkFaint#%{v:lua.require'ink.words'.ruler()}%)"
vim.o.number = false
vim.o.relativenumber = true
vim.o.signcolumn = "no"
vim.o.linebreak = true
vim.o.breakindentopt = "list:-1"
vim.o.smoothscroll = true
vim.opt.fillchars:append({ eob = " ", lastline = " " })

-- Undo steps back a sentence or clause at a time instead of a whole insert; a ga change (ink.alt)
-- stays one undo step.
for _, ch in ipairs({ ".", ",", "!", "?" }) do
	vim.keymap.set("i", ch, function()
		return require("ink.alt").editing() and ch or ch .. "<C-g>u"
	end, { expr = true })
end

require("ink.links")
require("ink.words")
require("ink.alt")

-- Order matters: these redraw on CursorMoved before ink.room's typewriter scrolling recenters.
require("ink.focus")
require("ink.margin")
require("ink.tables")
require("ink.inline")
require("ink.room")
