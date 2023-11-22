-- linter.lua
--
-- Configures linting using nvim-lint

return {
  'mfussenegger/nvim-lint',
  lazy = true,
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    -- Event to trigger linters
    linters_by_ft = {
      javascript = { 'eslint_d' },
      typescript = { 'eslint_d' },
      javascriptreact = { 'eslint_d' },
      typescriptreact = { 'eslint_d' },
      json = { 'jsonlint' },
      markdown = { 'vale' },
      htmldjango = { 'djlint' },
    },
  },
  config = function()
    local lint = require 'lint'
    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })

    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    vim.keymap.set('n', '<leader>cl', function()
      lint.try_lint()
    end, { desc = 'Trigger linting for current file' })
  end,
}
