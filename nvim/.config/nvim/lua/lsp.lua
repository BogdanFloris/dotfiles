-- lua/lsp.lua

local fzf = require("fzf-lua")
local ciderlsp_config = require("ciderlsp")

-- [[ LSP Attach Configuration ]]
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
	callback = function(ev)
		local bufnr = ev.buf
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client then
			return
		end

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
	{ "nixd" },
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

-- Register CiderLSP if binary exists
if vim.fn.executable("/google/bin/releases/cider/ciderlsp/ciderlsp") == 1 then
	vim.lsp.config("ciderlsp", ciderlsp_config)
	vim.lsp.enable("ciderlsp")
end

-- Register personal LSPs (ignore files under /google)
for _, lsp in pairs(lsps) do
	local name, config = lsp[1], lsp[2] or {}
	local original_root = config.root_dir
	config.root_dir = function(bufnr, on_dir)
		local fname = vim.api.nvim_buf_get_name(bufnr)
		if vim.startswith(fname, "/google") then
			return nil
		end
		local root
		if original_root then
			root = original_root(bufnr, on_dir)
		else
			local default_cfg = vim.lsp.config[name]
			local markers = default_cfg and default_cfg.root_markers or { ".git" }
			root = vim.fs.root(bufnr, markers)
		end
		if on_dir and root then
			on_dir(root)
		end
		return root
	end
	vim.lsp.config(name, config)
	vim.lsp.enable(name)
end
