-- lua/ink/words.lua
-- The word count in the ruler, plus the words written this session: "1318 words · +42".

local util = require("ink.util")

local M = {}

vim.api.nvim_create_autocmd("BufWinEnter", {
	group = util.group,
	callback = function(ev)
		if vim.b[ev.buf].ink_words == nil and util.is_text(ev.buf) then
			vim.b[ev.buf].ink_words = vim.fn.wordcount().words
		end
	end,
})

function M.ruler()
	local words = vim.fn.wordcount().words
	local start = vim.b.ink_words or words
	local count = words == start and (words .. " words") or ("%d words · %+d"):format(words, words - start)
	local prefix = "" -- "2/3 · " in alternatives, "3 stashed · " while the stash holds something
	for _, name in ipairs({ "ink.alt", "ink.stash" }) do
		local ok, mod = pcall(require, name)
		prefix = prefix .. (ok and mod.status() or "")
	end
	return prefix .. count
end

return M
