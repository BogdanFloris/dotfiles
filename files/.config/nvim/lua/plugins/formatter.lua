-- formatter.lua
--
-- Configures formatting using confirm.nvim

return {
  'stevearc/conform.nvim',
  lazy = true,
  event = { 'BufReadPre', 'BufNewFile' },
  cmd = 'ConformInfo',
  keys = {
    {
      '<leader>cf',
      function()
        require('conform').format { async = true, lsp_fallback = true }
      end,
      mode = '',
      desc = 'Format buffer',
    },
  },
  opts = {
    -- Define your formatters
    formatters_by_ft = {
      lua = { 'stylua' },
      javascript = { 'eslint_d', { 'prettierd', 'prettier' } },
      typescript = { 'eslint_d', { 'prettierd', 'prettier' } },
      javascriptreact = { 'eslint_d', { 'prettierd', 'prettier' } },
      typescriptreact = { 'eslint_d', { 'prettierd', 'prettier' } },
      css = { { 'prettierd', 'prettier' } },
      html = { { 'prettierd', 'prettier' } },
      htmldjango = { 'djlint' },
      json = { { 'prettierd', 'prettier' } },
      yaml = { { 'prettierd', 'prettier' } },
      markdown = { { 'prettierd', 'prettier' } },
      graphql = { { 'prettierd', 'prettier' } },
      sh = { 'shfmt' },
      python = { 'ruff_fix', 'ruff_format' },
      go = { 'gofumpt', 'goimports', 'golines' },
      sql = { 'sql_formatter' },
    },
    -- Set up format-on-save
    format_on_save = { timeout_ms = 500, lsp_fallback = true },
    -- Customize formatters
    formatters = {
      shfmt = {
        prepend_args = { '-i', '2' },
      },
      sql_formatter = {
        args = { '-l', 'postgresql' },
      },
    },
  },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
