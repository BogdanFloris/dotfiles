-- [[ Configure LSP ]]
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
	callback = function(ev)
		local bufnr = ev.buf
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client then
			return
		end

		local fzf = require("fzf-lua")
		local map = function(keys, func, desc, mode)
			vim.keymap.set(mode or "n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
		end

		map("gd", fzf.lsp_definitions, "Goto Definition")
		map("gr", fzf.lsp_references, "Goto References")
		map("gI", fzf.lsp_implementations, "Goto Implementation")
		map("<leader>D", fzf.lsp_typedefs, "Type Definition")
		map("<leader>ds", fzf.lsp_document_symbols, "Document Symbols")
		map("<leader>ws", fzf.lsp_live_workspace_symbols, "Workspace Symbols")

		-- Actions
		map("<leader>rn", vim.lsp.buf.rename, "Rename")
		map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
		map("<leader>k", vim.lsp.buf.signature_help, "Signature Help")
		map("gD", vim.lsp.buf.declaration, "Goto Declaration")

		-- Inlay hints
		if vim.lsp.inlay_hint then
			map("<leader>ch", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}), {})
			end, "Toggle Inlay Hints")
		end

		-- Ruff-specific
		if client.name == "ruff" then
			local function organize_imports()
				vim.lsp.buf.code_action({
					apply = true,
					context = { only = { "source.organizeImports" }, diagnostics = {} },
				})
			end
			map("<leader>co", organize_imports, "Organize Imports")
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

return {}
