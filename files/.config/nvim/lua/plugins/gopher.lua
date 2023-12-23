return {
  'olexsmir/gopher.nvim',
  ft = 'go',
  build = function()
    vim.cmd [[silent! GoInstallDeps]]
  end,
  commands = {
    go = 'go',
    gomodifytags = 'gomodifytags',
    gotests = '~/go/bin/gotests', -- also you can set custom command path
    impl = 'impl',
    iferr = 'iferr',
  },
}
