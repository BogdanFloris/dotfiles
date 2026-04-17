-- lua/lsp.lua

local fzf = require("fzf-lua")

-- [[ LSP Attach Configuration ]]
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
	callback = function(ev)
		local bufnr = ev.buf
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client then
			return
		end

		vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
		local map = function(keys, func, desc, mode)
			vim.keymap.set(mode or "n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
		end

		map("gd", fzf.lsp_definitions, "Goto Definition")
		map("gr", fzf.lsp_references, "Goto References")
		map("<leader>D", fzf.lsp_typedefs, "Type Definition")
		map("<leader>ws", fzf.lsp_live_workspace_symbols, "Workspace Symbols")

		-- Inlay hints toggle
		if vim.lsp.inlay_hint then
			map("<leader>ch", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}), {})
			end, "Toggle Inlay Hints")
		end

		-- Format with conform
		map("<leader>cf", function()
			require("conform").format({ async = true, lsp_fallback = true })
		end, "Format buffer")

		-- Ruff-specific: organize imports
		if client.name == "ruff" then
			map("<leader>co", function()
				vim.lsp.buf.code_action({
					apply = true,
					context = { only = { "source.organizeImports" }, diagnostics = {} },
				})
			end, "Organize Imports")
		end

		-- ESLint fix on save
		if client.name == "eslint" then
			vim.api.nvim_create_autocmd("BufWritePre", {
				buffer = bufnr,
				command = "EslintFixAll",
			})
		end
	end,
})

-- [[ LSP Server Configurations ]]
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
				"--clang-tidy",
			},
		},
	},
}

-- Apply LSP configurations
for _, lsp in pairs(lsps) do
	local name, config = lsp[1], lsp[2]
	if config then
		vim.lsp.config(name, config)
	end
	vim.lsp.enable(name)
end
