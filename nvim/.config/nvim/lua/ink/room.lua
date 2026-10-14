-- lua/ink/room.lua
-- The room itself: a centered zen window sized to the text, typewriter scrolling and autosave.

local c = require("ink.colors")
local tables = require("ink.tables")
local util = require("ink.util")

-- Typewriter scrolling: the line being written stays mid-screen.
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
	group = util.group,
	callback = function(ev)
		if util.is_text(ev.buf) then
			-- :normal steps the cursor back off the end of the line in insert mode, so restore it.
			local cursor = vim.api.nvim_win_get_cursor(0)
			vim.cmd("normal! zz")
			vim.api.nvim_win_set_cursor(0, cursor)
		end
	end,
})

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "FocusLost" }, {
	group = util.group,
	callback = function(ev)
		if util.is_text(ev.buf) and vim.bo[ev.buf].modified and vim.api.nvim_buf_get_name(ev.buf) ~= "" then
			vim.api.nvim_buf_call(ev.buf, function()
				vim.cmd("silent! update")
			end)
		end
	end,
})

-- Soft-wrapped drafts get a 70-column measure. Hard-wrapped docs (20+ prose lines, 95% of them
-- under 100 columns) get one that fits their lines, so each line doesn't spill into a stub.
local function measure(buf)
	local widths = {}
	for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
		if line:find("%S") and not line:find("^%s*[|#]") and not line:find("^%s*```") then
			widths[#widths + 1] = vim.fn.strdisplaywidth(line)
		end
	end
	table.sort(widths)
	local p95 = #widths >= 20 and widths[math.ceil(#widths * 0.95)] or 0
	return (p95 > 70 and p95 <= 100) and p95 or 70
end

local room -- the zen window holding the text
local margin = 4
local text_width = 70

vim.keymap.set("n", "<leader>mw", function()
	if room and room:valid() then
		room.opts.width = room.opts.width < vim.o.columns and vim.o.columns or text_width + margin
		room:update()
		tables.render(true)
	end
end, { desc = "Toggle full-width layout (wide tables)" })

vim.api.nvim_create_autocmd("VimEnter", {
	group = util.group,
	once = true,
	callback = function()
		text_width = measure(vim.api.nvim_get_current_buf())
		room = Snacks.zen({
			toggles = { dim = false, git_signs = false, mini_diff_signs = false },
			win = {
				width = text_width + margin,
				wo = { statuscolumn = "%!v:lua.require'ink.margin'.column()" },
				backdrop = { transparent = false, blend = 99, bg = c.bg },
			},
			on_close = function()
				-- Closing the text window means leaving the room.
				if vim.v.exiting == vim.NIL then
					vim.schedule(function()
						vim.cmd("confirm qa")
					end)
				end
			end,
		})
		vim.cmd("normal! G$")
		tables.render(true)
		vim.cmd("startinsert!")
	end,
})
