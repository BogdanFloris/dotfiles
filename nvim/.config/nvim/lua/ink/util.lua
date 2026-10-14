-- lua/ink/util.lua

local M = {}

M.group = vim.api.nvim_create_augroup("ink", { clear = true })

function M.is_text(buf)
	return vim.bo[buf].buftype == "" and vim.api.nvim_buf_is_loaded(buf)
end

return M
