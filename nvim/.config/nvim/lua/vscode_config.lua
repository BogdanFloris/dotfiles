-- lua/vscode_config.lua
local vscode = require("vscode")
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"windwp/nvim-ts-autotag",
		},
		build = ":TSUpdate",
		config = function()
			---@diagnostic disable-next-line: missing-fields
			require("nvim-treesitter.config").setup({
				ensure_installed = { "kotlin", "java", "cpp", "lua", "markdown" },
				highlight = { enable = true },
				autotag = { enable = true },
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<c-space>",
						node_incremental = "<c-space>",
						scope_incremental = "<c-s>",
						node_decremental = "<M-space>",
					},
				},
			})
		end,
	},
	-- You need this for the <leader>cs symbols we talked about
	{ "ibhagwan/fzf-lua" },
})

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.clipboard = "unnamedplus"
vim.wo.relativenumber = true

vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.hl.on_yank()
	end,
})

-------------------------------------------------------------------------------
-- Keybindings (Using VSCode Actions)
-------------------------------------------------------------------------------
-- Format: vim.keymap.set(mode, shortcut, action)

-- General
vim.keymap.set("n", "<C-x>", function()
	vscode.action("workbench.action.closeActiveEditor")
end)
vim.keymap.set("n", "<leader>?", function()
	vscode.action("workbench.action.openRecent")
end)
vim.keymap.set("n", "<leader><space>", function()
	vscode.action("workbench.action.showAllEditors")
end)
vim.keymap.set("n", "<leader>e", function()
	vscode.action("editor.action.showHover")
end)
vim.keymap.set("n", "<leader>wm", function()
	require("vscode").action("workbench.action.joinEditorGroupLeft")
end, { desc = "Merge split left (Unsplit)" })

vim.keymap.set("n", "<leader>w1", function()
	require("vscode").action("workbench.action.editorLayoutSingle")
end, { desc = "Force single layout (Close all splits)" })

-- Search
vim.keymap.set("n", "<leader>/", function()
	vscode.action("actions.find")
end)
vim.keymap.set("n", "<leader>sf", function()
	vscode.action("workbench.action.quickOpen")
end)
vim.keymap.set("n", "<leader>sg", function()
	vscode.action("workbench.action.findInFiles")
end)
vim.keymap.set("n", "<leader>sd", function()
	vscode.action("workbench.action.showErrorsWarnings")
end)

-- LSP / Navigation
vim.keymap.set("n", "gd", function()
	vscode.action("editor.action.revealDefinition")
end)
vim.keymap.set("n", "gr", function()
	vscode.action("editor.action.goToReferences")
end)
vim.keymap.set("n", "gI", function()
	vscode.action("editor.action.goToImplementation")
end)
vim.keymap.set("n", "K", function()
	vscode.action("editor.action.showDefinitionPreviewHover")
end)
vim.keymap.set("n", "<leader>rn", function()
	vscode.action("editor.action.rename")
end)
vim.keymap.set("n", "<leader>ca", function()
	vscode.action("editor.action.quickFix")
end)
vim.keymap.set("n", "<leader>cf", function()
	vscode.action("editor.action.formatDocument")
end)

-- UI / Zen
vim.keymap.set("n", "<leader>-", function()
	vscode.action("workbench.view.explorer")
end)
vim.keymap.set("n", "<leader>z", function()
	vscode.action("workbench.action.toggleZenMode")
end)
vim.keymap.set("n", "<leader>;", function()
	vscode.action("breadcrumbs.focusAndSelect")
end)

-- Git
vim.keymap.set("n", "]c", function()
	vscode.action("workbench.action.editor.nextChange")
end)
vim.keymap.set("n", "[c", function()
	vscode.action("workbench.action.editor.previousChange")
end)

-- Cursors
vim.keymap.set("x", "<leader>m", function()
	vscode.action("editor.action.addCursorsToAtEndOfLinesSelected")
end)

-- Symbols
vim.keymap.set("n", "<leader>ss", function()
	vscode.action("workbench.action.showAllSymbols")
end)
