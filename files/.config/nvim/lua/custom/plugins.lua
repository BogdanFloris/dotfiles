local overrides = require "custom.configs.overrides"

local plugins = {

  -- vim-kitty-navigator
  {
    "knubie/vim-kitty-navigator",
    lazy = false,
    build = "cp ./*.py ~/.config/kitty/",
  },

  -- nvim-treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = { "nvim-treesitter/nvim-treesitter-context", opts = { after = "nvim-treesitter" } },
    opts = {
      ensure_installed = {
        "html",
        "css",
        "bash",
        "rust",
        "javascript",
        "typescript",
        "tsx",
        "json",
        "go",
        "gomod",
        "gosum",
        "c",
        "terraform",
      },
    },
  },

  -- nvim-lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "jose-elias-alvarez/null-ls.nvim",
      config = function()
        require "custom.configs.null-ls"
      end,
    },
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end,
  },

  -- mason
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "html-lsp",
        "djlint",
        "css-lsp",
        "prettier",
        "eslint_d",
        "stylua",
        "rust-analyzer",
        "clang-format",
        "eslint-lsp",
        "typescript-language-server",
        "tailwindcss-language-server",
        "json-lsp",
        "gopls",
        "golines",
        "goimports",
        "pyright",
        "ruff-lsp",
        "mypy",
        "black",
        "shellcheck",
        "bash-language-server",
      },
    },
  },

  -- copilot
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = overrides.copilot,
    -- config = function()
    -- require("copilot").setup {}
    -- end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      {
        "zbirenbaum/copilot-cmp",
        config = function()
          require("copilot_cmp").setup()
        end,
      },
    },
    opts = {
      sources = {
        { name = "nvim_lsp", group_index = 2 },
        { name = "copilot", group_index = 2 },
        { name = "luasnip", group_index = 2 },
        { name = "buffer", group_index = 2 },
        { name = "nvim_lua", group_index = 2 },
        { name = "path", group_index = 2 },
      },
    },
  },
  {
    "rust-lang/rust.vim",
    ft = "rust",
    init = function()
      vim.g.rustfmt_autosave = 1
    end,
  },
  {
    "simrat39/rust-tools.nvim",
    ft = "rust",
    dependencies = "neovim/nvim-lspconfig",
    opts = function()
      return require "custom.configs.rust-tools"
    end,
    config = function(_, opts)
      ---@diagnostic disable-next-line: different-requires
      require("rust-tools").setup(opts)
    end,
  },
  {
    "olexsmir/gopher.nvim",
    ft = "go",
    config = function(_, opts)
      require("gopher").setup(opts)
    end,
    build = function()
      vim.cmd [[silent! GoInstallDeps]]
    end,
  },
  {
    "jose-elias-alvarez/typescript.nvim",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    dependencies = "neovim/nvim-lspconfig",
    opts = function()
      return require "custom.configs.typescript"
    end,
    config = function(_, opts)
      ---@diagnostic disable-next-line: different-requires
      require("typescript").setup(opts)
    end,
  },
}

return plugins
