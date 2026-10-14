-- lua/ink/links.lua
-- Pasting a URL over a selection turns the selection into a link: select words, paste, get
-- [words](url). Covers terminal pastes (Ctrl+Shift+V, through vim.paste) and p with a URL register.

local M = {}

local function url(text)
	text = vim.trim(text or "")
	return text:match("^%a[%w+.-]*://%S+$") and text or nil
end

local function one_line_selection()
	return vim.api.nvim_get_mode().mode == "v" and vim.fn.getpos("v")[2] == vim.fn.getpos(".")[2]
end

-- Turns the charwise selection on one line into [text](href); false when there is none.
function M.wrap(href)
	if not one_line_selection() then
		return false
	end
	local a, b = vim.fn.getpos("v"), vim.fn.getpos(".")
	local text = vim.fn.getregion(a, b, { type = "v" })[1]
	local row, col = a[2] - 1, math.min(a[3], b[3]) - 1
	local link = "[" .. text .. "](" .. href .. ")"
	vim.api.nvim_buf_set_text(0, row, col, row, col + #text, { link })
	vim.cmd("normal! " .. vim.keycode("<Esc>"))
	vim.api.nvim_win_set_cursor(0, { row + 1, col + #link - 1 })
	return true
end

function M.wrap_register(reg)
	if not M.wrap(url(vim.fn.getreg(reg)) or "") then
		vim.cmd('normal! "' .. reg .. "p")
	end
end

vim.keymap.set("x", "p", function()
	if vim.v.count == 0 and one_line_selection() and url(vim.fn.getreg(vim.v.register)) then
		return ("<Cmd>lua require('ink.links').wrap_register(%q)<CR>"):format(vim.v.register)
	end
	return "p"
end, { expr = true, desc = "Paste (a URL over a selection makes a link)" })

-- Terminal pastes can arrive in chunks, so a paste over a selection is collected before deciding.
local paste = vim.paste
local pending
vim.paste = function(lines, phase)
	if phase == -1 or phase == 1 then
		pending = one_line_selection() and {} or nil
	end
	if not pending then
		return paste(lines, phase)
	end
	local first = 1
	if #pending > 0 then -- a chunk can split a line: its first line continues the last one
		pending[#pending] = pending[#pending] .. lines[1]
		first = 2
	end
	vim.list_extend(pending, lines, first)
	if phase == -1 or phase == 3 then
		local all = pending
		pending = nil
		local href = url(table.concat(all, "\n"))
		if href and M.wrap(href) then
			return true
		end
		return paste(all, -1)
	end
	return true
end

return M
