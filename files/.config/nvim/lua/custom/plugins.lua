local overrides = require "custom.configs.overrides"

local plugins = {
  -- nvim-treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-context",
      "nvim-treesitter/nvim-treesitter-textobjects",
      opts = { after = "nvim-treesitter" },
    },
    opts = {
      ensure_installed = {
        "html",
        "css",
        "scss",
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
        "cpp",
        "cmake",
        "make",
        "terraform",
        "sql",
        "zig",
        "python",
        "markdown",
        "dockerfile",
        "gitignore",
        "java",
        "kotlin",
        "jq",
        "org",
        "regex",
        "ruby",
        "wgsl",
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
          keymaps = {
            -- You can use the capture groups defined in textobjects.scm
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            ["]f"] = "@function.outer",
            ["]]"] = "@class.outer",
          },
          goto_next_end = {
            ["]F"] = "@function.outer",
            ["]["] = "@class.outer",
          },
          goto_previous_start = {
            ["[f"] = "@function.outer",
            ["[["] = "@class.outer",
          },
          goto_previous_end = {
            ["[F"] = "@function.outer",
            ["[]"] = "@class.outer",
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ["<leader>a"] = "@parameter.inner",
          },
          swap_previous = {
            ["<leader>A"] = "@parameter.inner",
          },
        },
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
        "clangd",
        "eslint-lsp",
        "typescript-language-server",
        "tailwindcss-language-server",
        "json-lsp",
        "gopls",
        "golines",
        "goimports",
        "pyright",
        "ruff",
        "mypy",
        "black",
        "shellcheck",
        "bash-language-server",
        "sqlls",
        "sql-formatter",
        "zls",
        "dockerfile-language-server",
        "solargraph",
        "rubocop",
        "wgsl-analyzer",
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
  -- dressing.nvim
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
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
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    opts = {},
    lazy = false,
  },
  { "tpope/vim-dadbod", lazy = false },
  { "kristijanhusak/vim-dadbod-ui", lazy = false },
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup {
        -- Configuration here, or leave empty to use defaults
      }
    end,
  },
}

return plugins
