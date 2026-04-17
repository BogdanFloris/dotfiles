-- lua/keymaps.lua

local fzf = require("fzf-lua")

-- [[ Basic Keymaps ]]
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
vim.keymap.set("n", "<C-q>", "<cmd>qa<CR>", { desc = "Close all and quit" })
vim.keymap.set("n", "<C-x>", "<cmd>bd<CR>", { desc = "Close buffer" })
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Diagnostics ]]
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })

-- [[ FZF / Search ]]
vim.keymap.set("n", "<leader>?", fzf.oldfiles, { desc = "Find recently opened files" })
vim.keymap.set("n", "<leader><space>", fzf.buffers, { desc = "Find existing buffers" })
vim.keymap.set("n", "<leader>/", fzf.lgrep_curbuf, { desc = "Fuzzily search in current buffer" })
vim.keymap.set("n", "<leader>gf", fzf.git_files, { desc = "Search Git Files" })
vim.keymap.set("n", "<leader>sf", fzf.files, { desc = "Search Files" })
vim.keymap.set("n", "<leader>sh", fzf.help_tags, { desc = "Search Help" })
vim.keymap.set("n", "<leader>sw", fzf.grep_cword, { desc = "Search current Word" })
vim.keymap.set("n", "<leader>sg", fzf.live_grep, { desc = "Search by Grep" })
vim.keymap.set("n", "<leader>sd", fzf.diagnostics_workspace, { desc = "Search Diagnostics" })
vim.keymap.set("n", "<leader>sr", fzf.resume, { desc = "Search Resume" })
vim.keymap.set("n", "<leader>sm", fzf.marks, { desc = "Search Marks" })
vim.keymap.set("n", "<leader>st", "<cmd>FzfLua todo_comments<cr>", { desc = "Search todo comments" })

-- [[ Oil ]]
vim.keymap.set("n", "<leader>-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- [[ Dropbar ]]
vim.keymap.set("n", "<leader>;", function() require("dropbar.api").pick() end, { desc = "Pick symbols in winbar" })
vim.keymap.set("n", "[;", function() require("dropbar.api").goto_context_start() end, { desc = "Go to start of current context" })
vim.keymap.set("n", "];", function() require("dropbar.api").select_next_context() end, { desc = "Select next context" })

-- [[ Persistence ]]
vim.keymap.set("n", "<leader>qs", function()
	require("persistence").load()
end, { desc = "Restore session for cwd" })
vim.keymap.set("n", "<leader>qS", function()
	require("persistence").select()
end, { desc = "Select a session" })

-- [[ Snacks ]]
vim.keymap.set("n", "<leader>dd", function()
	Snacks.dashboard.open()
end, { desc = "Open Dashboard" })
vim.keymap.set("n", "<leader>un", function()
	Snacks.notifier.show_history()
end, { desc = "Notification History" })
vim.keymap.set({ "n", "t" }, "<leader>zm", function()
	Snacks.zen()
end, { desc = "Zen mode" })
