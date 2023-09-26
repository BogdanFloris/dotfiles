local M = {}

M.disabled = {
  t = {
    ["<A-h>"] = "",
  },

  n = {
    ["<A-h>"] = "",
    ["<leader>v"] = "",
  },
}

M.telescope = {
  n = {
    ["<leader>cc"] = { "<cmd> Telescope <CR>", "Telescope" },
    ["gr"] = { "<cmd> Telescope lsp_references <CR>", "Telescope LSP references" },
    ["gi"] = { "<cmd> Telescope lsp_implementations <CR>", "Telescope LSP implementations" },
    ["gd"] = { "<cmd> Telescope lsp_definitions <CR>", "Telescope LSP definitions" },
  },
}

M.typescript = {
  n = {
    ["<leader>co"] = { "<cmd>TypescriptOrganizeImports<CR>", "Typescript Organize Imports" },
    ["<leader>cR"] = { "<cmd>TypescriptRenameFile<CR>", "Typescript Rename File" },
  },
}

M.general = {
  n = {
    ["<C-q>"] = { "<cmd> q <CR>", "Quit" },
  },
}

M.harpoon = {
  n = {
    ["<leader>h"] = {
      function()
        require("harpoon.ui").toggle_quick_menu()
      end,
      "Toggle quick menu",
    },
    ["<leader>hc"] = {
      function()
        require("harpoon.mark").clear_all()
      end,
      "Clear all marks",
    },
    ["<leader>ha"] = {
      function()
        require("harpoon.mark").add_file()
      end,
      "Add file",
    },
    ["<leader>1"] = {
      function()
        require("harpoon.ui").nav_file(1)
      end,
      "Navigate to file 1",
    },
    ["<leader>2"] = {
      function()
        require("harpoon.ui").nav_file(2)
      end,
      "Navigate to file 2",
    },
    ["<leader>3"] = {
      function()
        require("harpoon.ui").nav_file(3)
      end,
      "Navigate to file 3",
    },
    ["<leader>4"] = {
      function()
        require("harpoon.ui").nav_file(4)
      end,
      "Navigate to file 4",
    },
    ["<leader>5"] = {
      function()
        require("harpoon.ui").nav_file(5)
      end,
      "Navigate to file 5",
    },
    ["<leader>6"] = {
      function()
        require("harpoon.ui").nav_file(6)
      end,
      "Navigate to file 6",
    },
    ["<leader>7"] = {
      function()
        require("harpoon.ui").nav_file(7)
      end,
      "Navigate to file 7",
    },
    ["<leader>8"] = {
      function()
        require("harpoon.ui").nav_file(8)
      end,
      "Navigate to file 8",
    },
    ["<leader>9"] = {
      function()
        require("harpoon.ui").nav_file(9)
      end,
      "Navigate to file 9",
    },
  },
}

M.persistence = {
  n = {
    ["<leader>qs"] = {
      function()
        require("persistence").load()
      end,
      "Restore session",
    },
    ["<leader>ql"] = {
      function()
        require("persistence").load { last = true }
      end,
      "Restore last session",
    },
    ["<leader>qd"] = {
      function()
        require("persistence").stop()
      end,
      "Stop persistence",
    },
  },
}

return M
