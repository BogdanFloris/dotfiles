-- lua/plugins.lua

vim.pack.add({
	"https://github.com/ellisonleao/gruvbox.nvim",
	"https://github.com/tpope/vim-sleuth",
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/folke/lazydev.nvim",
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/windwp/nvim-ts-autotag",
	"https://github.com/windwp/nvim-autopairs",
	"https://github.com/kylechui/nvim-surround",
	"https://github.com/folke/persistence.nvim",
	"https://github.com/folke/which-key.nvim",
	"https://github.com/folke/snacks.nvim",
	"https://github.com/Bekaboo/dropbar.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/echasnovski/mini.icons",
	"https://github.com/stevearc/oil.nvim",
	"https://github.com/ibhagwan/fzf-lua",
	"https://github.com/lewis6991/gitsigns.nvim",
	"https://github.com/stevearc/conform.nvim",
	"https://github.com/folke/todo-comments.nvim",
	"https://github.com/christoomey/vim-tmux-navigator",
	"https://github.com/mrcjkb/rustaceanvim",
	"https://github.com/pmizio/typescript-tools.nvim",
	"https://github.com/nvim-lua/plenary.nvim",
})

-- [[ Plugin Configurations ]]
require("gruvbox").setup({
	inverse = true,
})
require("lazydev").setup({
	library = {
		{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
	},
})
---@diagnostic disable-next-line: missing-fields
require("nvim-treesitter.config").setup({
	ensure_installed = {
		"asm",
		"bp",
		"c",
		"cpp",
		"cmake",
		"make",
		"terraform",
		"sql",
		"zig",
		"markdown",
		"dockerfile",
		"gitignore",
		"graphql",
		"java",
		"kotlin",
		"jq",
		"regex",
		"ruby",
		"wgsl",
		"glsl",
		"go",
		"gomod",
		"gosum",
		"lua",
		"python",
		"rust",
		"toml",
		"tsx",
		"javascript",
		"typescript",
		"vimdoc",
		"vim",
		"bash",
		"html",
		"htmldjango",
		"css",
		"scss",
		"json",
		"http",
		"xml",
		"yaml",
	},
	auto_install = false,
	highlight = { enable = true },
	autotag = { enable = true },
})

require("nvim-autopairs").setup({})
require("nvim-surround").setup({})
require("persistence").setup({})
require("which-key").setup({})
require("which-key").add({
	{ "<leader>c", group = "[C]ode" },
	{ "<leader>g", group = "[G]it" },
	{ "<leader>q", group = "[Q]uit/Session" },
	{ "<leader>s", group = "[S]earch" },
	{ "<leader>w", group = "[W]orkspace" },
})

require("snacks").setup({
	dashboard = {
		enabled = true,
		sections = {
			{ section = "header" },
			{ section = "keys", gap = 1, padding = 1 },
			{ section = "recent_files", indent = 2, padding = 1 },
			{ section = "projects", indent = 2, padding = 1 },
		},
	},
	bigfile = { enabled = true },
	indent = { enabled = true },
	input = { enabled = true },
	notifier = { enabled = true },
	quickfile = { enabled = true },
	scope = { enabled = true },
	zen = { enabled = true },
})

require("oil").setup({})

local fzf = require("fzf-lua")
fzf.setup({
	"fzf-native",
	winopts = {
		---@diagnostic disable-next-line: missing-fields
		preview = {
			default = "builtin",
		},
	},
})
fzf.register_ui_select()

require("gitsigns").setup({
	on_attach = function(bufnr)
		local gs = require("gitsigns")

		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

		map({ "n", "v" }, "]c", function()
			if vim.wo.diff then
				return "]c"
			end
			vim.schedule(function()
				gs.nav_hunk("next")
			end)
			return "<Ignore>"
		end, { expr = true, desc = "Jump to next hunk" })

		map({ "n", "v" }, "[c", function()
			if vim.wo.diff then
				return "[c"
			end
			vim.schedule(function()
				gs.nav_hunk("prev")
			end)
			return "<Ignore>"
		end, { expr = true, desc = "Jump to previous hunk" })

		map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview git hunk" })
		map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset git hunk" })
		map("n", "<leader>gb", gs.blame_line, { desc = "Blame git line" })
	end,
})

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		javascriptreact = { "prettier" },
		typescriptreact = { "prettier" },
		html = { "prettier" },
		css = { "prettier" },
		json = { "prettier" },
		markdown = { "prettier" },
		htmldjango = { "djlint" },
		go = { "goimports", "gofumpt", "golines" },
		rust = { "rustfmt" },
		sh = { "shfmt" },
		sql = { "sql_formatter" },
		c = { "clang-format" },
		cpp = { "clang-format" },
		nix = { "alejandra" },
	},
})

require("todo-comments").setup({})

local dropbar_api = require("dropbar.api")
vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })

require("typescript-tools").setup({})
vim.g.rustaceanvim = {
	server = {
		standalone = true,
		settings = {
			["rust-analyzer"] = {
				cargo = {
					allFeatures = true,
					loadOutDirsFromCheck = true,
					runBuildScripts = true,
				},
				checkOnSave = {
					allFeatures = true,
					command = "clippy",
					extraArgs = { "--", "-W", "clippy::pedantic" },
				},
				procMacro = {
					enable = true,
					ignored = {
						["async-trait"] = { "async_trait" },
						["napi-derive"] = { "napi" },
						["async-recursion"] = { "async_recursion" },
					},
				},
			},
		},
	},
}
