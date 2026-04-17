-- init.lua
-- @BogdanFloris
--
vim.g.mapleader = " "
vim.g.maplocalleader = " "

if vim.g.vscode then
	require("vscode_config")
else
	vim.o.hlsearch = false
	vim.wo.relativenumber = true
	vim.o.mouse = "a"
	vim.o.clipboard = "unnamedplus"
	vim.o.breakindent = true
	vim.o.undofile = true
	vim.o.ignorecase = true
	vim.o.smartcase = true
	vim.wo.signcolumn = "yes"
	vim.o.updatetime = 250
	vim.o.timeoutlen = 300
	vim.o.tabstop = 4
	vim.o.expandtab = true
	vim.o.termguicolors = true
	vim.opt.laststatus = 3
	vim.o.foldcolumn = "1"
	vim.o.foldlevel = 99
	vim.o.foldlevelstart = 99
	vim.o.foldenable = true

	-- Native completion settings
	vim.o.completeopt = "menuone,noselect,fuzzy"

	vim.filetype.add({
		extension = {
			bp = "bp",
			gotmpl = "gotmpl",
			templ = "templ",
			wgsl = "wgsl",
			zon = "zig",
		},
		filename = {
			["Android.bp"] = "bp",
		},
		pattern = {
			["*.Dockerfile.*"] = "dockerfile",
			["*/templates/**/*.html"] = "htmldjango",
		},
	})

	-- Remember cursor location in files
	vim.api.nvim_create_autocmd("BufReadPost", {
		callback = function()
			local mark = vim.api.nvim_buf_get_mark(0, '"')
			if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
				vim.api.nvim_win_set_cursor(0, mark)
			end
		end,
	})

	-- Highlight on yank
	vim.api.nvim_create_autocmd("TextYankPost", {
		desc = "Highlight when yanking (copying) text",
		group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
		callback = function()
			vim.hl.on_yank()
		end,
	})

	-- Load modules
	require("plugins")
	require("keymaps")
	require("lsp")

	vim.cmd("colorscheme gruvbox")
end
