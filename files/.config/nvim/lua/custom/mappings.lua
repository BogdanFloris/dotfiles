local M = {}

M.disabled = {
  t = {
    ["<A-h>"] = "",
  },

  n = {
    ["<A-h>"] = "",
  },
}

M.abc = {
  n = {
    ["<leader>tb"] = { "<cmd> ToggleTabline <CR>", "Toggle Tabufline" },
    ["<leader>cc"] = { "<cmd> Telescope <CR>", "Telescope" },
    ["gr"] = { "<cmd> Telescope lsp_references <CR>", "Telescope LSP references" },
    ["gi"] = { "<cmd> Telescope lsp_implementations <CR>", "Telescope LSP implementations" },
    ["gd"] = { "<cmd> Telescope lsp_definitions <CR>", "Telescope LSP definitions" },
    ["<C-q>"] = { "<cmd> q <CR>", "Quit" },
    ["<leader>co"] = { "<cmd>TypescriptOrganizeImports<CR>", "Typescript Organize Imports" },
    ["<leader>cR"] = { "<cmd>TypescriptRenameFile<CR>", "Typescript Rename File" },
  },
}

return M
