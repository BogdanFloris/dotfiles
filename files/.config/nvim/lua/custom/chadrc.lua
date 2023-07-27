---@type ChadrcConfig
local M = {}
local ag = vim.api.nvim_create_augroup
local au = vim.api.nvim_create_autocmd

M.ui = { theme = "gruvbox" }

M.plugins = "custom.plugins"

M.mappings = require "custom.mappings"

-- GROUPS:
local disable_node_modules_eslint_group = ag("DisableNodeModulesEslint", { clear = true })

-- AUTO-COMMANDS:
au({ "BufNewFile", "BufRead" }, {
  pattern = { "**/node_modules/**", "node_modules", "/node_modules/*" },
  callback = function()
    vim.diagnostic.disable(0)
  end,
  group = disable_node_modules_eslint_group,
})

au("QuitPre", {
  callback = function()
    local tree_wins = {}
    local floating_wins = {}
    local wins = vim.api.nvim_list_wins()
    for _, w in ipairs(wins) do
      local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))
      if bufname:match "NvimTree_" ~= nil then
        table.insert(tree_wins, w)
      end
      if vim.api.nvim_win_get_config(w).relative ~= "" then
        table.insert(floating_wins, w)
      end
    end
    if 1 == #wins - #floating_wins - #tree_wins then
      -- Should quit, so we close all invalid windows.
      for _, w in ipairs(tree_wins) do
        vim.api.nvim_win_close(w, true)
      end
    end
  end,
})

return M
