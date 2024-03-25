return {
  {
    'schrieveslaach/sonarlint.nvim',
    url = 'https://gitlab.com/schrieveslaach/sonarlint.nvim',
    config = function()
      local sonarlint = require 'sonarlint'
      sonarlint.setup {
        server = {
          cmd = {
            'sonarlint-language-server',
            -- Ensure that sonarlint-language-server uses stdio channel
            '-stdio',
            '-analyzers',
            -- paths to the analyzers you need, using those for python and java in this example
            vim.fn.expand '~/.local/share/nvim/mason/share/sonarlint-analyzers/sonarpython.jar',
            vim.fn.expand '~/.local/share/nvim/mason/share/sonarlint-analyzers/sonarjs.jar',
          },
        },
        filetypes = {
          'typescript',
          'javascript',
          'typescriptreact',
          'javascriptreact',
        },
      }
    end,
  },
}
