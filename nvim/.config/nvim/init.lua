-- init.lua
-- @BogdanFloris
--
vim.g.mapleader = " "
vim.g.maplocalleader = " "

if vim.g.vscode then
	require("vscode_config")
else
	-- [[ Install `lazy.nvim` plugin manager ]]
	--    https://github.com/folke/lazy.nvim
	--    `:help lazy.nvim.txt` for more info
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

	vim.filetype.add({
		extension = {
			bp = "bp",
			gotmpl = "gotmpl",
			templ = "templ",
			wgsl = "wgsl",
			-- zig.zon filetype is not supported by default
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
	-- Fix for Android.bp files that do not start treesitter for some reason
	vim.api.nvim_create_autocmd({ "FileType" }, {
		pattern = "bp",
		callback = function()
			vim.treesitter.start()
		end,
	})

	require("lazy").setup({
		-- Detect tabstop and shiftwidth automatically
		"tpope/vim-sleuth",

		-- Buf del
		"ojroques/nvim-bufdel",

		{
			"vimwiki/vimwiki",
			event = "BufEnter *.md",
			keys = { "<leader>ww", "<leader>wt" },
		},

		{
			"ellisonleao/gruvbox.nvim",
			priority = 1000,
			config = function()
				require("gruvbox").setup({
					inverse = true,
				})
			end,
		},

		{
			-- LSP Configuration & Plugins
			"neovim/nvim-lspconfig",
			dependencies = {
				{ "mason-org/mason.nvim", opts = {} },
				{ "j-hui/fidget.nvim", opts = {} },
			},
		},

		{
			"windwp/nvim-autopairs",
			event = "InsertEnter",
			config = true,
		},

		{
			"folke/lazydev.nvim",
			ft = "lua", -- only load on lua files
			opts = {
				library = {
					-- See the configuration section for more details
					-- Load luvit types when the `vim.uv` word is found
					{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				},
			},
		},

		-- Lua
		{
			"folke/persistence.nvim",
			event = "BufReadPre",
			opts = {},
		},

		{
			-- Nvim Surround
			"kylechui/nvim-surround",
			version = "*", -- Use for stability; omit to use `main` branch for the latest features
			event = "VeryLazy",
			config = function()
				require("nvim-surround").setup({})
			end,
		},

		-- Useful plugin to show you pending keybinds.
		{
			"folke/which-key.nvim",
			event = "VeryLazy",
			opts = {},
			keys = {

				{ "<leader>c", group = "[C]ode" },
				{ "<leader>c_", hidden = true },
				{ "<leader>d", group = "[D]ocument" },
				{ "<leader>d_", hidden = true },
				{ "<leader>g", group = "[G]it" },
				{ "<leader>g_", hidden = true },
				{ "<leader>h", group = "[H]arpoon" },
				{ "<leader>h_", hidden = true },
				{ "<leader>p", group = "More git" },
				{ "<leader>p_", hidden = true },
				{ "<leader>r", group = "[R]ename" },
				{ "<leader>r_", hidden = true },
				{ "<leader>s", group = "[S]earch" },
				{ "<leader>s_", hidden = true },
				{ "<leader>w", group = "[W]orkspace" },
				{ "<leader>w_", hidden = true },
			},
		},
		{
			-- Adds git related signs to the gutter, as well as utilities for managing changes
			"lewis6991/gitsigns.nvim",
			opts = {
				-- See `:help gitsigns.txt`
				signs = {
					add = { text = "+" },
					change = { text = "~" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
				},
				on_attach = function(bufnr)
					vim.keymap.set(
						"n",
						"<leader>ph",
						require("gitsigns").preview_hunk,
						{ buffer = bufnr, desc = "Preview git hunk" }
					)
					vim.keymap.set(
						"n",
						"<leader>rh",
						require("gitsigns").reset_hunk,
						{ buffer = bufnr, desc = "Reset git hunk" }
					)
					vim.keymap.set(
						"n",
						"<leader>bh",
						require("gitsigns").blame_line,
						{ buffer = bufnr, desc = "Blame git line" }
					)

					-- don't override the built-in and fugitive keymaps
					local gs = package.loaded.gitsigns
					vim.keymap.set({ "n", "v" }, "]c", function()
						if vim.wo.diff then
							return "]c"
						end
						vim.schedule(function()
							gs.next_hunk()
						end)
						return "<Ignore>"
					end, { expr = true, buffer = bufnr, desc = "Jump to next hunk" })
					vim.keymap.set({ "n", "v" }, "[c", function()
						if vim.wo.diff then
							return "[c"
						end
						vim.schedule(function()
							gs.prev_hunk()
						end)
						return "<Ignore>"
					end, { expr = true, buffer = bufnr, desc = "Jump to previous hunk" })
				end,
			},
		},

		{
			-- Vim Tmux Navigator
			"christoomey/vim-tmux-navigator",
			event = "VeryLazy",
		},

		{
			-- Set lualine as statusline
			"nvim-lualine/lualine.nvim",
			-- See `:help lualine.txt`
			opts = {
				options = {
					icons_enabled = false,
					theme = "gruvbox",
					component_separators = "|",
					section_separators = "",
				},
			},
		},

		{
			-- File tree
			"stevearc/oil.nvim",
			opts = {},
			dependencies = { "nvim-tree/nvim-web-devicons" },
			config = function()
				require("oil").setup({})
				vim.keymap.set("n", "<leader>-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
			end,
		},

		-- "gc" to comment visual regions/lines
		{ "numToStr/Comment.nvim", opts = {} },

		{
			"folke/todo-comments.nvim",
			dependencies = { "nvim-lua/plenary.nvim" },
			opts = {
				search = {
					-- keeping this here in case I have a big project and want to narrow the search
					pattern = [[\b(KEYWORDS):]],
				},
			},
		},

		-- Fuzzy Finder (files, lsp, etc)
		{
			"ibhagwan/fzf-lua",
			dependencies = { "echasnovski/mini.icons" },
			config = function()
				local fzf = require("fzf-lua")
				fzf.setup({
					"fzf-native",
					winopts = {
						height = 0.85,
						width = 0.80,
						preview = {
							default = "builtin",
						},
					},
					keymap = {
						builtin = {
							["<C-d>"] = "preview-page-down",
							["<C-u>"] = "preview-page-up",
						},
					},
				})
				-- This makes fzf-lua the default provider for vim.ui.select
				-- (Code actions, etc)
				fzf.register_ui_select()
			end,
		},

		{
			"kevinhwang91/nvim-ufo",
			dependencies = { "kevinhwang91/promise-async" },
			config = function()
				require("ufo").setup({
					---@diagnostic disable-next-line: unused-local
					provider_selector = function(bufnr, filetype, buftype)
						return { "treesitter", "indent" }
					end,
				})

				vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
				vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
			end,
		},

		{
			-- Highlight, edit, and navigate code
			"nvim-treesitter/nvim-treesitter",
			dependencies = {
				"windwp/nvim-ts-autotag",
			},
			build = ":TSUpdate",
			config = function()
				---@diagnostic disable-next-line: missing-fields
				require("nvim-treesitter.configs").setup({
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

		{
			"folke/trouble.nvim",
			opts = {},
			cmd = "Trouble",
			keys = {
				{
					"<leader>xx",
					"<cmd>Trouble diagnostics toggle<cr>",
					desc = "Diagnostics (Trouble)",
				},
				{
					"<leader>xX",
					"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
					desc = "Buffer Diagnostics (Trouble)",
				},
				{
					"<leader>cs",
					"<cmd>Trouble symbols toggle focus=false<cr>",
					desc = "Symbols (Trouble)",
				},
				{
					"<leader>cl",
					"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
					desc = "LSP Definitions / references / ... (Trouble)",
				},
				{
					"<leader>xL",
					"<cmd>Trouble loclist toggle<cr>",
					desc = "Location List (Trouble)",
				},
				{
					"<leader>xQ",
					"<cmd>Trouble qflist toggle<cr>",
					desc = "Quickfix List (Trouble)",
				},
			},
		},

		{
			"vhyrro/luarocks.nvim",
			priority = 1000,
			config = true,
			opts = {
				rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" },
			},
		},
		{
			"pmizio/typescript-tools.nvim",
			dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
			opts = {},
		},

		{
			"Bekaboo/dropbar.nvim",
			config = function()
				local dropbar_api = require("dropbar.api")
				vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
				vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
				vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
			end,
		},

		require("plugins.blink"),
		require("plugins.conform"),
		require("plugins.harpoon"),
		require("plugins.rustancean"),
		require("plugins.snacks"),
	}, {})

	-- [[ Setting options ]]
	vim.cmd("colorscheme gruvbox")

	-- Set highlight on search
	vim.o.hlsearch = false

	-- Make line numbers default
	vim.wo.relativenumber = true

	-- Enable mouse mode
	vim.o.mouse = "a"

	-- Sync clipboard between OS and Neovim.
	--  Remove this option if you want your OS clipboard to remain independent.
	--  See `:help 'clipboard'`
	vim.o.clipboard = "unnamedplus"

	-- Enable break indent
	vim.o.breakindent = true

	-- Save undo history
	vim.o.undofile = true

	-- Case-insensitive searching UNLESS \C or capital in search
	vim.o.ignorecase = true
	vim.o.smartcase = true

	-- Keep signcolumn on by default
	vim.wo.signcolumn = "yes"

	-- Decrease update time
	vim.o.updatetime = 250
	vim.o.timeoutlen = 300

	-- Set completeopt to have a better completion experience
	vim.o.completeopt = "menuone,noselect"

	-- Tabs
	vim.o.tabstop = 4
	vim.o.expandtab = true

	-- Folds
	vim.o.foldcolumn = "1"
	vim.o.foldlevel = 99
	vim.o.foldlevelstart = 99
	vim.o.foldenable = true

	-- views can only be fully collapsed with the global statusline
	vim.opt.laststatus = 3

	vim.o.termguicolors = true
	vim.opt.guicursor =
		"n-v-c:block-blinkwait175-blinkoff150-blinkon175,i-ci-ve:ver25-blinkwait175-blinkoff150-blinkon175"

	-- Enable Rest NVIM
	vim.g.rest_nvim = {}

	-- Remember cursor location in files
	vim.api.nvim_create_autocmd("BufReadPost", {
		callback = function()
			local mark = vim.api.nvim_buf_get_mark(0, '"')
			if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
				vim.api.nvim_win_set_cursor(0, mark)
			end
		end,
	})

	-- [[ Basic Keymaps ]]

	-- Keymaps for better default experience
	-- See `:help vim.keymap.set()`
	vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
	vim.keymap.set("n", "<C-q>", "<cmd> qa <CR>", { desc = "Close all and quit" })
	vim.keymap.set("n", "<C-x>", "<cmd> bd <CR>", { desc = "Close buffer" })
	vim.keymap.set("n", "<leader>bd", "<cmd> BufDel <CR>", { desc = "Close buffer and preserve layout" })

	-- Remap for dealing with word wrap
	vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
	vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

	-- Diagnostic keymaps
	vim.keymap.set("n", "[d", function()
		vim.diagnostic.jump({ count = -1, float = true })
	end, { desc = "Go to previous diagnostic message" })
	vim.keymap.set("n", "]d", function()
		vim.diagnostic.jump({ count = 1, float = true })
	end, { desc = "Go to next diagnostic message" })
	vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
	vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

	vim.keymap.set("n", "<leader>st", "<cmd>FzfLua todo_comments<cr>", { desc = "Search todo comments" })

	-- [[ Highlight on yank ]]
	vim.api.nvim_create_autocmd("TextYankPost", {
		desc = "Highlight when yanking (copying) text",
		group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
		callback = function()
			vim.hl.on_yank()
		end,
	})

	-- [[ Configure FZF ]]
	local fzf = require("fzf-lua")

	vim.keymap.set("n", "<leader>?", fzf.oldfiles, { desc = "[?] Find recently opened files" })
	vim.keymap.set("n", "<leader><space>", fzf.buffers, { desc = "[ ] Find existing buffers" })
	vim.keymap.set("n", "<leader>/", fzf.lgrep_curbuf, { desc = "[/] Fuzzily search in current buffer" })

	vim.keymap.set("n", "<leader>gf", fzf.git_files, { desc = "Search [G]it [F]iles" })
	vim.keymap.set("n", "<leader>sf", fzf.files, { desc = "[S]earch [F]iles" })
	vim.keymap.set("n", "<leader>sh", fzf.help_tags, { desc = "[S]earch [H]elp" })
	vim.keymap.set("n", "<leader>sw", fzf.grep_cword, { desc = "[S]earch current [W]ord" })
	vim.keymap.set("n", "<leader>sg", fzf.live_grep, { desc = "[S]earch by [G]rep" })
	vim.keymap.set("n", "<leader>sd", fzf.diagnostics_workspace, { desc = "[S]earch [D]iagnostics" })
	vim.keymap.set("n", "<leader>sr", fzf.resume, { desc = "[S]earch [R]esume" })
	vim.keymap.set("n", "<leader>sm", fzf.marks, { desc = "[S]earch [M]arks" })

	-- Setup LSP servers directly
	require("mason").setup({})

	local lsps = {
		{ "graphql" },
		{ "protols" },
		{
			"basedpyright",
			{
				settings = {
					pyright = {
						disableOrganizeImports = true, -- Using Ruff
					},
				},
			},
		},
		{ "ruff" },
		{ "eslint" },
		{
			"sqlls",
			{ filetypes = { "sql", "psql" } },
		},
		{
			"glsl_analyzer",
			{ filetypes = { "glsl" } },
		},
		{ "nil_ls" },
		{ "lua_ls" },
		{
			"zls",
			{ filetypes = { "zig" } },
		},
		{
			"clangd",
			{
				cmd = {
					"clangd",
					"--offset-encoding=utf-16",
				},
			},
		},
	}

	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

	require("lsp_tools")
	vim.lsp.config("*", {
		capabilities = capabilities,
	})

	for _, lsp in pairs(lsps) do
		local name, config = lsp[1], lsp[2]
		if config then
			vim.lsp.config(name, config)
		end
		vim.lsp.enable(name)
	end
end
