local null_ls = require "null-ls"

local formatting = null_ls.builtins.formatting
local lint = null_ls.builtins.diagnostics

local sources = {
  -- ESLint
  lint.eslint.with {
    command = "eslint_d",
  },

  -- Prettier
  formatting.prettier.with {
    filetypes = {
      "html",
      "css",
      "scss",
      "json",
      "jsonc",
      "yaml",
      "typescript",
      "typescriptreact",
      "javascript",
      "javascriptreact",
      "markdown",
      "graphql",
    },
  },

  -- Typescript
  require "typescript.extensions.null-ls.code-actions",

  -- Lua
  formatting.stylua.with { filetypes = { "lua" } },

  -- Shell
  lint.shellcheck,

  -- Go
  formatting.gofmt,
  formatting.goimports,
  formatting.golines,

  -- Python
  lint.mypy,
  lint.ruff,
  formatting.black,

  -- HTML templates
  lint.djlint,
  formatting.djlint.with {
    filetypes = { "html", "django", "jinja.html", "htmldjango" },
  },
}

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

null_ls.setup {
  debug = true,
  sources = sources,
  on_attach = function(client, bufnr)
    if client.supports_method "textDocument/formatting" then
      vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format { async = false }
        end,
      })
    end
  end,
}
