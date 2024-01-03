-- none-ls.nvim
--
-- Configuration for none-ls.nvim

local lsp_formatting = function(bufnr)
  vim.lsp.buf.format {
    filter = function(client)
      return client.name == 'null-ls'
    end,
    bufnr = bufnr,
  }
end

return {
  'nvimtools/none-ls.nvim',
  config = function()
    local null_ls = require 'null-ls'
    local augroup = vim.api.nvim_create_augroup('LspFormatting', {})

    null_ls.setup {
      sources = {
        -- formatters
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.prettierd,
        null_ls.builtins.formatting.eslint_d,
        null_ls.builtins.formatting.djlint,
        null_ls.builtins.formatting.rustywind,
        null_ls.builtins.formatting.ruff,
        null_ls.builtins.formatting.shfmt,
        null_ls.builtins.formatting.gofumpt,
        null_ls.builtins.formatting.goimports,
        null_ls.builtins.formatting.golines,
        null_ls.builtins.formatting.sql_formatter,
        null_ls.builtins.formatting.rustfmt,

        -- diagnostics
        null_ls.builtins.diagnostics.shellcheck,
        null_ls.builtins.diagnostics.vale,
        null_ls.builtins.diagnostics.jsonlint,
        null_ls.builtins.diagnostics.djlint,
        null_ls.builtins.diagnostics.hadolint,
        null_ls.builtins.diagnostics.sqlfluff,

        -- code actions
        null_ls.builtins.code_actions.gomodifytags,
        null_ls.builtins.code_actions.impl,
      },

      on_attach = function(client, bufnr)
        if client.supports_method 'textDocument/formatting' then
          vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
          vim.api.nvim_create_autocmd('BufWritePre', {
            group = augroup,
            buffer = bufnr,
            callback = function()
              lsp_formatting(bufnr)
            end,
          })
        end
      end,
    }
    vim.keymap.set('n', '<leader>cf', vim.lsp.buf.format, { desc = 'LSP: Format' })
  end,
}
