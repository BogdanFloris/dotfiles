local M = {}

M.copilot = {
  suggestion = {
    enable = false,
  },
  copilot_node_command = vim.fn.expand "$HOME" .. "/.nvm/versions/node/v18.16.1/bin/node",
  panel = {
    enable = false,
  },
  filetypes = {
    markdown = true,
  },
}

return M
