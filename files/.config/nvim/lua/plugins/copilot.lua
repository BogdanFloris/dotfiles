-- copilot.lua
--
-- Configures Github Copilot using copilot.lua plugin.

return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup {
        suggestion = {
          enabled = false,
        },
        copilot_node_command = vim.fn.expand '$HOME' .. '/.nvm/versions/node/v18.17.0/bin/node',
        panel = {
          enabled = false,
        },
        filetypes = {
          markdown = true,
        },
      }
    end,
  },

  {
    'zbirenbaum/copilot-cmp',
    config = function()
      require('copilot_cmp').setup()
    end,
  },
}
