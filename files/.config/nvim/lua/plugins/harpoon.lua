return {
  {
    'ThePrimeagen/harpoon',
    config = function()
      local harpoon = require 'harpoon'

      harpoon.setup {}

      vim.keymap.set('n', '<leader>ha', require('harpoon.mark').add_file)
      vim.keymap.set('n', '<leader>h', require('harpoon.ui').toggle_quick_menu)

      for i = 1, 5 do
        local command = string.format('<leader>%s', i)
        vim.keymap.set('n', command, function()
          require('harpoon.ui').nav_file(i)
        end)
      end
    end,
  },
}
