-- plugins/conform.lua

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	opts = {
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
			-- Use a sub-list to run only the first available formatter
			-- Example: tailwind = { "rustywind" }
		},
		-- Set up format-on-save
		-- format_on_save = {
		-- 	timeout_ms = 500,
		-- 	lsp_fallback = true,
		-- },
	},
}
