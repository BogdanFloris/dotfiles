local on_attach = require('lsp_tools').on_attach

return {
  'mrcjkb/rustaceanvim',
  version = '^4',
  ft = { 'rust' },
  opts = {
    server = {
      on_attach = on_attach,
      standalone = true,
      settings = {
        ['rust-analyzer'] = {
          cargo = {
            allFeatures = true,
            loadOutDirsFromCheck = true,
            runBuildScripts = true,
          },
          -- Add clippy lints for Rust.
          checkOnSave = {
            allFeatures = true,
            command = 'clippy',
            extraArgs = { '--', '-W', 'clippy::pedantic' },
          },
          procMacro = {
            enable = true,
            ignored = {
              ['async-trait'] = { 'async_trait' },
              ['napi-derive'] = { 'napi' },
              ['async-recursion'] = { 'async_recursion' },
            },
          },
        },
      },
    },
  },
  config = function(_, opts)
    vim.g.rustaceanvim = vim.tbl_deep_extend('force', {}, opts or {})
  end,
}
