-- neotest.lua
--
-- Neotest plugin configuration for running tests from Neovim
return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    -- runners
    'nvim-neotest/neotest-jest',
  },
  keys = {
    {
      '<leader>tn',
      function()
        require('neotest').run.run()
      end,
      desc = 'Neotest Test Nearest',
    },
    {
      '<leader>tf',
      function()
        require('neotest').run.run(vim.fn.expand '%')
      end,
      desc = 'Neotest Test File',
    },
    {
      '<leader>to',
      function()
        require('neotest').output.open()
      end,
      desc = 'Neotest Output',
    },
  },
  config = function()
    require('neotest').setup {
      adapters = {
        require 'neotest-jest',
      },
    }
  end,
}
