-- lua/ink/room.lua
-- The room itself: a centered zen window sized to the text, with typewriter scrolling.

local tables = require("ink.tables")
local util = require("ink.util")

local M = {}

-- Typewriter scrolling: the line being written stays mid-screen.
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
	group = util.group,
	callback = function(ev)
		if util.focus and util.is_text(ev.buf) then
			-- :normal steps the cursor back off the end of the line in insert mode, so restore it.
			local cursor = vim.api.nvim_win_get_cursor(0)
			vim.cmd("normal! zz")
			vim.api.nvim_win_set_cursor(0, cursor)
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
local parent -- the normal window hidden behind the room
local margin = require("ink.margin").width
local text_width = 70
local ready = false -- render-markdown has drawn the room

-- Motions that land in the hidden window (e.g. <C-l> via vim-herdr-navigation) bounce back, so they
-- cross into herdr panes instead of closing the room. Runs before zen's own WinEnter handler.
vim.api.nvim_create_autocmd("WinEnter", {
	group = util.group,
	callback = function()
		if room and room:win_valid() and vim.api.nvim_get_current_win() == parent then
			vim.api.nvim_set_current_win(room.win)
		end
	end,
})

-- Called by render-markdown after each render (see `on` in ink/init.lua).
function M.rendered(ctx)
	if room and ctx.win == room.win then
		ready = true
	end
end

vim.keymap.set("n", "<leader>mw", function()
	if room and room:valid() then
		room.opts.width = room.opts.width < vim.o.columns and vim.o.columns or text_width + margin
		room:update()
		tables.render(true)
	end
end, { desc = "Toggle full-width layout (wide tables)" })

vim.keymap.set("n", "<leader>mf", function()
	util.focus = not util.focus
	require("ink.focus").update()
	if util.focus then
		vim.cmd("normal! zz")
	end
end, { desc = "Toggle focus (dimming, typewriter scrolling)" })

vim.api.nvim_create_autocmd("VimEnter", {
	group = util.group,
	once = true,
	callback = function()
		text_width = measure(vim.api.nvim_get_current_buf())
		-- An opaque backdrop in the colorscheme's own background hides the window behind the room.
		local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
		parent = vim.api.nvim_get_current_win()
		room = Snacks.zen({
			toggles = { dim = false, git_signs = false, mini_diff_signs = false },
			win = {
				width = text_width + margin,
				wo = {
					statuscolumn = "%!v:lua.require'ink.margin'.column()",
					winhighlight = "NormalFloat:Normal,NonText:InkHidden",
				},
				backdrop = { transparent = false, blend = 99, bg = bg and string.format("#%06x", bg) or nil },
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
		vim.cmd("normal! G$zz")
		tables.render(true)
		-- render-markdown renders after the first frame (vim.schedule plus a debounce that drops
		-- requests), so render the room now through its updater and wait for any async parse.
		if vim.bo.filetype == "markdown" then
			pcall(function()
				require("render-markdown.core.ui").updater.new(vim.api.nvim_get_current_buf(), room.win, true):run()
			end)
			vim.wait(200, function()
				return ready
			end, 1)
		end
	end,
})

return M
