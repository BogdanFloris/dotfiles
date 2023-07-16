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
    ["gr"] = { "<cmd> Telescope lsp_references <CR>", "Telescope LSP references" },
    ["gi"] = { "<cmd> Telescope lsp_implementations <CR>", "Telescope LSP implementations" },
    ["gd"] = { "<cmd> Telescope lsp_definitions <CR>", "Telescope LSP definitions" },
  },
}

return M
