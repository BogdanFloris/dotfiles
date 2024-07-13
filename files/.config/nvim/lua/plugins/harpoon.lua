return {
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    config = function()
      local harpoon = require 'harpoon'

      harpoon:setup {}

      vim.keymap.set('n', '<leader>ha', function()
        harpoon:list():add()
      end, { desc = 'Add file to Harpoon' })
      vim.keymap.set('n', '<leader>hh', function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = 'Open Harpoon' })

      for i = 1, 9 do
        local command = string.format('<leader>%s', i)
        local desc = string.format('Open Harpoon %s', i)
        vim.keymap.set('n', command, function()
          harpoon:list():select(i)
        end, { desc = desc })
      end
    end,
  },
}
