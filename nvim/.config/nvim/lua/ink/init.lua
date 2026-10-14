-- lua/ink/init.lua
-- Ink, the writing room: Neovim in writing mode, in the current terminal. Loaded when INK_WRITING
-- is set (the `ink` script, or INK_WRITING=1 nvim file.md).

vim.env.INK_WRITING = nil

require("ink.colors")

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
vim.o.rulerformat = "%=%#InkFaint#%{wordcount().words} words"
vim.o.number = false
vim.o.relativenumber = false
vim.o.signcolumn = "no"
vim.o.linebreak = true
vim.o.breakindentopt = "list:-1"
vim.o.smoothscroll = true
vim.opt.fillchars:append({ eob = " ", lastline = " " })

-- Order matters: these redraw on CursorMoved before ink.room's typewriter scrolling recenters.
require("ink.focus")
require("ink.margin")
require("ink.tables")
require("ink.room")
