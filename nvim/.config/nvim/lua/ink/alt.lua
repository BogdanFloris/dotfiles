-- lua/ink/alt.lua
-- Alternatives: a span of text with several phrasings, one of them in the text. Select text and press
-- <leader>va to type a new variant in its place, then cycle with ]v / [v. Spans are extmarks, so they
-- follow edits, and the active variant is whatever text the span holds, so undo stays in sync.

local util = require("ink.util")

local M = {}
local ns = vim.api.nvim_create_namespace("ink_alt")
local spans = {} -- spans[buf][extmark id] = { variants = { ... }, active = index, editing = bool }
local popup -- { win = ..., buf = ..., id = span }
local lost, extra = {}, {} -- per buffer: saved alternatives that no longer match, other footer keys
local FOOTER = "<!-- ink_buffer"

local function of(buf)
	spans[buf] = spans[buf] or {}
	return spans[buf]
end

local function echo(msg)
	vim.api.nvim_echo({ { msg, "InkFaint" } }, false, {})
end

-- The span's range, or nil once all of its text is deleted (an undo can bring it back).
local function range(buf, id)
	local m = vim.api.nvim_buf_get_extmark_by_id(buf, ns, id, { details = true })
	if not m[1] or m[3].invalid then
		return nil
	end
	return m[1], m[2], m[3].end_row, m[3].end_col
end

local function text(buf, id)
	local sr, sc, er, ec = range(buf, id)
	return sr and table.concat(vim.api.nvim_buf_get_text(buf, sr, sc, er, ec, {}), "\n")
end

local function mark(buf, sr, sc, er, ec, opts)
	local base = { end_row = er, end_col = ec, hl_group = "InkAlt", invalidate = true }
	return vim.api.nvim_buf_set_extmark(buf, ns, sr, sc, vim.tbl_extend("force", base, opts or {}))
end

-- Replaces the span's text, keeping the extmark around the new text.
local function put(buf, id, value)
	local sr, sc, er, ec = range(buf, id)
	local lines = vim.split(value, "\n", { plain = true })
	vim.api.nvim_buf_set_text(buf, sr, sc, er, ec, lines)
	mark(buf, sr, sc, sr + #lines - 1, #lines == 1 and sc + #lines[1] or #lines[#lines], { id = id })
end

local function remove(buf, id)
	vim.api.nvim_buf_del_extmark(buf, ns, id)
	of(buf)[id] = nil
end

-- An edit inside a span rewrites its active variant; an undo back to another variant selects it.
local function sync(buf)
	for id, span in pairs(spans[buf] or {}) do
		local t = not span.editing and text(buf, id)
		if t and t ~= "" and t ~= span.variants[span.active] then
			local found
			for i, v in ipairs(span.variants) do
				if v == t then
					found = i
				end
			end
			if found then
				span.active = found
			else
				span.variants[span.active] = t
			end
		end
	end
end

-- The innermost span under the cursor.
local function at_cursor(buf)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]
	local best, size
	for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, { row, col }, { row, col }, { details = true, overlap = true })) do
		local id, sr, sc, d = m[1], m[2], m[3], m[4]
		local inside = (row > sr or col >= sc) and (row < d.end_row or col < d.end_col)
		if inside and not d.invalid and of(buf)[id] then
			local s = (d.end_row - sr) * 100000 + d.end_col - sc
			if not size or s < size then
				best, size = id, s
			end
		end
	end
	return best
end

local function close_popup()
	if popup and vim.api.nvim_win_is_valid(popup.win) then
		vim.api.nvim_win_close(popup.win, true)
	end
	popup = nil
end

-- Lists the variants under the span (above it near the bottom), the active one marked.
local function show_popup(buf, id)
	close_popup()
	local span, sr, sc, er, ec = of(buf)[id], range(buf, id)
	if not sr then
		return
	end
	local first, last = vim.fn.screenpos(0, sr + 1, sc + 1), vim.fn.screenpos(0, er + 1, math.max(ec, 1))
	if first.row == 0 or last.row == 0 then
		return
	end
	local lines, width = {}, 0
	for i, v in ipairs(span.variants) do
		lines[i] = (i == span.active and "• " or "  ") .. v:gsub("\n", " ⏎ ")
		width = math.max(width, vim.fn.strdisplaywidth(lines[i]))
	end
	local textoff = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff
	width = math.min(width + 1, vim.api.nvim_win_get_width(0) - textoff - 2)
	local row = last.row
	if row + #lines + 2 > vim.o.lines - 1 then
		row = first.row - #lines - 3
	end
	local pbuf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, lines)
	for i = 1, #lines do
		vim.api.nvim_buf_set_extmark(pbuf, ns, i - 1, 0, { line_hl_group = i == span.active and "Normal" or "InkDim" })
	end
	local win = vim.api.nvim_open_win(pbuf, false, {
		relative = "editor",
		row = row,
		col = math.max(first.col - 4, 0), -- border and marker, so variants line up with the text
		width = width,
		height = #lines,
		style = "minimal",
		border = "rounded",
		title = (" %d/%d "):format(span.active, #span.variants),
		title_pos = "right",
		footer = " ]v [v ",
		footer_pos = "right",
		focusable = false,
		noautocmd = true,
		zindex = 60,
	})
	vim.wo[win].winhighlight = "NormalFloat:Normal,FloatBorder:InkFaint,FloatTitle:InkFaint,FloatFooter:InkFaint"
	vim.wo[win].wrap = false
	popup = { win = win, buf = buf, id = id }
end

-- Clears the span and starts insert mode in its place; leaving insert stores what was typed as a new
-- variant (nothing typed puts the previous variant back).
local function edit(buf, id)
	local span = of(buf)[id]
	local sr, sc = range(buf, id)
	span.editing = true
	close_popup()
	put(buf, id, "")
	mark(buf, sr, sc, sr, sc, { id = id, right_gravity = false, end_right_gravity = true })
	vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
	vim.cmd(sc >= #vim.api.nvim_buf_get_lines(buf, sr, sr + 1, false)[1] and "startinsert!" or "startinsert")
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = util.group,
		buffer = buf,
		callback = function()
			if not (vim.v.event.old_mode:match("^i") and vim.v.event.new_mode:match("^n")) then
				return
			end
			span.editing = false
			local typed = text(buf, id)
			if typed == nil then
				remove(buf, id)
			elseif typed == "" then
				put(buf, id, span.variants[span.active])
				if #span.variants < 2 then
					remove(buf, id)
				end
			else
				table.insert(span.variants, typed)
				span.active = #span.variants
				local _, _, er, ec = range(buf, id)
				mark(buf, sr, sc, er, ec, { id = id }) -- stop growing with typed text
			end
			return true
		end,
	})
end

-- Saved as a trailing HTML comment (the format from the Ink Buffer idea doc); the buffer never holds it.
local function footer(buf)
	local list = vim.deepcopy(lost[buf] or {})
	for id, span in pairs(spans[buf] or {}) do
		local sr, sc, er, ec = range(buf, id)
		if sr and not span.editing and #span.variants > 1 then
			list[#list + 1] =
				{ row = sr, start_col = sc, end_row = er, end_col = ec, active = span.active - 1, variants = span.variants }
		end
	end
	if #list == 0 and vim.tbl_isempty(extra[buf] or {}) then
		return nil
	end
	table.sort(list, function(a, b)
		return a.row < b.row or (a.row == b.row and a.start_col < b.start_col)
	end)
	local data = vim.tbl_extend("force", extra[buf] or {}, { alternatives = list })
	return { "", FOOTER, (vim.json.encode(data):gsub("%-%->", "--\\u003e")), "-->" }
end

-- Writes the buffer plus the footer, so :w works as usual.
local function writer(buf)
	if vim.b[buf].ink_alt_writer then
		return
	end
	vim.b[buf].ink_alt_writer = true
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		group = util.group,
		buffer = buf,
		callback = function(ev)
			sync(buf)
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			vim.list_extend(lines, footer(buf) or {})
			local path = vim.fn.fnamemodify(ev.match, ":p")
			if vim.fn.writefile(lines, path) ~= 0 then
				return vim.api.nvim_echo({ { "Ink: could not write " .. path, "ErrorMsg" } }, true, {})
			end
			if path == vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p") then
				vim.bo[buf].modified = false
			end
			echo(('"%s" %dL written'):format(vim.fn.fnamemodify(path, ":~:."), #lines))
		end,
	})
end

-- Where a saved alternative's active text is now: its saved place, else the nearest copy of the text.
local function locate(buf, a)
	local want = type(a.variants) == "table" and a.variants[(a.active or 0) + 1]
	if type(want) ~= "string" or want == "" then
		return nil
	end
	local ok, got = pcall(vim.api.nvim_buf_get_text, buf, a.row, a.start_col, a.end_row, a.end_col, {})
	if ok and table.concat(got, "\n") == want then
		return a.row, a.start_col, a.end_row, a.end_col
	end
	local lines, starts, offset = vim.api.nvim_buf_get_lines(buf, 0, -1, false), {}, 1
	for i, l in ipairs(lines) do
		starts[i], offset = offset, offset + #l + 1
	end
	local function pos(byte) -- byte in the joined text to 0-based row, col
		local row = 1
		while starts[row + 1] and starts[row + 1] <= byte do
			row = row + 1
		end
		return row - 1, byte - starts[row]
	end
	local whole, best, dist = table.concat(lines, "\n"), nil, nil
	local s = whole:find(want, 1, true)
	while s do
		local row, col = pos(s)
		if not dist or math.abs(row - (a.row or 0)) < dist then
			local er, ec = pos(s + #want)
			best, dist = { row, col, er, ec }, math.abs(row - (a.row or 0))
		end
		s = whole:find(want, s + 1, true)
	end
	if best then
		return unpack(best)
	end
end

-- Strips the footer on load, without an undo step, and puts the alternatives back.
local function read(buf)
	spans[buf], lost[buf], extra[buf] = {}, {}, {}
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local n = #lines
	while n > 0 and lines[n] == "" do
		n = n - 1
	end
	if n < 3 or lines[n] ~= "-->" or lines[n - 2] ~= FOOTER then
		return
	end
	local ok, data = pcall(vim.json.decode, lines[n - 1])
	if not ok or type(data) ~= "table" then
		return
	end
	local first = (n > 3 and lines[n - 3] == "") and n - 3 or n - 2
	local undolevels = vim.bo[buf].undolevels
	vim.bo[buf].undolevels = -1
	vim.api.nvim_buf_set_lines(buf, first - 1, -1, false, {})
	vim.bo[buf].undolevels = undolevels
	vim.bo[buf].modified = false
	local alts = type(data.alternatives) == "table" and data.alternatives or {}
	data.alternatives = nil
	extra[buf] = data
	for _, a in ipairs(alts) do
		local sr, sc, er, ec = locate(buf, a)
		if sr then
			of(buf)[mark(buf, sr, sc, er, ec)] = { variants = a.variants, active = (a.active or 0) + 1 }
		else
			table.insert(lost[buf], a)
		end
	end
	if #lost[buf] > 0 then
		echo(("%d set(s) of alternatives no longer match the text; they stay in the file"):format(#lost[buf]))
	end
	writer(buf)
end

-- <leader>va on a selection makes it a span; inside a span it adds a variant.
local function add()
	local buf = vim.api.nvim_get_current_buf()
	local mode = vim.api.nvim_get_mode().mode
	if mode == "n" then
		local id = at_cursor(buf)
		if not id then
			return echo("Select the text first (viw, vis, vip)")
		end
		sync(buf)
		return edit(buf, id)
	end
	local a, b = vim.fn.getpos("v"), vim.fn.getpos(".")
	if b[2] < a[2] or (b[2] == a[2] and b[3] < a[3]) then
		a, b = b, a
	end
	local sr, sc, er, ec = a[2] - 1, a[3] - 1, b[2] - 1, nil
	if mode == "V" then
		sc, ec = 0, #vim.api.nvim_buf_get_lines(buf, er, er + 1, false)[1]
	elseif mode == "v" then
		ec = b[3] - 1 + #vim.fn.getregion(b, b, { type = "v" })[1]
	else
		return echo("Alternatives need a character or line selection")
	end
	vim.cmd("normal! " .. vim.keycode("<Esc>"))
	for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, { sr, sc }, { er, ec }, { details = true, overlap = true })) do
		if not m[4].invalid and of(buf)[m[1]] then
			return echo("That overlaps text that already has alternatives")
		end
	end
	local original = table.concat(vim.api.nvim_buf_get_text(buf, sr, sc, er, ec, {}), "\n")
	if original == "" then
		return
	end
	local id = mark(buf, sr, sc, er, ec)
	of(buf)[id] = { variants = { original }, active = 1 }
	writer(buf)
	edit(buf, id)
end

local function cycle(step)
	local buf = vim.api.nvim_get_current_buf()
	local id = at_cursor(buf)
	if not id then
		return
	end
	sync(buf)
	local span = of(buf)[id]
	span.active = (span.active - 1 + step * vim.v.count1) % #span.variants + 1
	put(buf, id, span.variants[span.active])
	local sr, sc = range(buf, id)
	vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
	show_popup(buf, id)
end

local function keep()
	local buf = vim.api.nvim_get_current_buf()
	local id = at_cursor(buf)
	if not id then
		return
	end
	sync(buf)
	local span = of(buf)[id]
	close_popup()
	remove(buf, id)
	echo(("Kept variant %d of %d"):format(span.active, #span.variants))
end

local function drop()
	local buf = vim.api.nvim_get_current_buf()
	local id = at_cursor(buf)
	if not id then
		return
	end
	sync(buf)
	local span = of(buf)[id]
	table.remove(span.variants, span.active)
	span.active = math.min(span.active, #span.variants)
	put(buf, id, span.variants[span.active])
	local sr, sc = range(buf, id)
	vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
	if #span.variants > 1 then
		return show_popup(buf, id)
	end
	close_popup()
	remove(buf, id)
	echo("Dropped; only one variant was left, so the alternatives are gone")
end

pcall(function()
	require("which-key").add({ { "<leader>v", group = "Alternati[v]es" } })
end)
vim.keymap.set({ "n", "x" }, "<leader>va", add, { desc = "Alternative: type a new variant in place" })
vim.keymap.set("n", "<leader>vk", keep, { desc = "Alternatives: keep this variant" })
vim.keymap.set("n", "<leader>vd", drop, { desc = "Alternatives: drop this variant" })
vim.keymap.set("n", "]v", function() cycle(1) end, { desc = "Next alternative" })
vim.keymap.set("n", "[v", function() cycle(-1) end, { desc = "Previous alternative" })

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
	group = util.group,
	callback = function(ev)
		if next(spans[ev.buf] or {}) then
			sync(ev.buf)
		end
	end,
})

vim.api.nvim_create_autocmd("CursorHold", {
	group = util.group,
	callback = function(ev)
		local id = next(spans[ev.buf] or {}) and at_cursor(ev.buf)
		if id and not (popup and popup.id == id) then
			show_popup(ev.buf, id)
		end
	end,
})

vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave", "WinScrolled" }, {
	group = util.group,
	callback = function(ev)
		if popup and (ev.event ~= "CursorMoved" or at_cursor(ev.buf) ~= popup.id) then
			close_popup()
		end
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	group = util.group,
	pattern = { "*.md", "*.markdown" },
	callback = function(ev)
		read(ev.buf)
	end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
	group = util.group,
	callback = function(ev)
		spans[ev.buf], lost[ev.buf], extra[ev.buf] = nil, nil, nil
	end,
})

M.spans, M.ns = spans, ns

return M
