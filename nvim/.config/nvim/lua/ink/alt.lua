-- lua/ink/alt.lua
-- Alternatives: several phrasings of a span of text, one of them in the text. ga works like c (gaiw,
-- gais, gaip, gac, visual ga) but keeps the old text as an alternative, and ]v / [v cycle through them.
-- It rides on Vim's own change, so one u undoes it (alternative included), <C-r> redoes it and . repeats
-- it. Spans are extmarks; each variant remembers the change that made (or dropped) it, so undo, redo and
-- cycling stay in step with the text.

local footer = require("ink.footer")
local util = require("ink.util")

local M = {}
local ns = vim.api.nvim_create_namespace("ink_alt")
local spans = {} -- spans[buf][extmark id] = { variants = { { text, born?, died? } }, active, vis, ... }
local newest = {} -- per buffer: the highest change number seen, to tell new changes from undo and redo
local lost = {} -- per buffer: saved alternatives that no longer match the text, kept for the footer
local pending -- noted by ga (or by . repeating it) until its change reaches insert mode
local ga_last = {} -- per buffer: the last change made with a command was a ga change, so . repeats it as ga
local own = false -- the next change is Ink's own (cycling, dropping), which . doesn't repeat
local popup -- { win, buf, id }

local function of(buf)
	spans[buf] = spans[buf] or {}
	return spans[buf]
end

local function echo(msg)
	vim.api.nvim_echo({ { msg, "InkFaint" } }, false, {})
end

local function changenr(buf)
	return vim.api.nvim_buf_call(buf, vim.fn.changenr)
end

-- The span's extmark position, also once all of its text was deleted.
local function pos(buf, id)
	local m = vim.api.nvim_buf_get_extmark_by_id(buf, ns, id, { details = true })
	if m[1] then
		return m[1], m[2], m[3].end_row, m[3].end_col, m[3].invalid
	end
end

-- The span's range, or nil while all of its text is deleted (an undo can bring it back).
local function range(buf, id)
	local sr, sc, er, ec, invalid = pos(buf, id)
	if sr and not invalid then
		return sr, sc, er, ec
	end
end

local function text(buf, id)
	local sr, sc, er, ec = range(buf, id)
	return sr and table.concat(vim.api.nvim_buf_get_text(buf, sr, sc, er, ec, {}), "\n")
end

-- While a variant is being written the mark survives the deletion and grows with the typed text.
local function remark(buf, id, sr, sc, er, ec)
	local span = of(buf)[id]
	vim.api.nvim_buf_set_extmark(buf, ns, sr, sc, {
		id = id,
		end_row = er,
		end_col = ec,
		hl_group = span.painted and "InkAlt" or nil,
		right_gravity = not span.editing,
		end_right_gravity = span.editing == true,
		invalidate = not span.editing,
	})
end

local function add_span(buf, sr, sc, er, ec, span)
	local id = vim.api.nvim_buf_set_extmark(buf, ns, sr, sc, {})
	of(buf)[id] = span
	remark(buf, id, sr, sc, er, ec)
	return id
end

local function remove(buf, id)
	vim.api.nvim_buf_del_extmark(buf, ns, id)
	of(buf)[id] = nil
end

-- Replaces the span's text, keeping the extmark around the new text.
local function put(buf, id, value)
	local sr, sc, er, ec = range(buf, id)
	local lines = vim.split(value, "\n", { plain = true })
	vim.api.nvim_buf_set_text(buf, sr, sc, er, ec, lines)
	remark(buf, id, sr, sc, sr + #lines - 1, #lines == 1 and sc + #lines[1] or #lines[#lines])
end

-- The variants that exist at change number cur: made at or before it, not dropped by then.
local function visible(span, cur)
	return vim.tbl_filter(function(v)
		return (not v.born or v.born <= cur) and (not v.died or cur < v.died)
	end, span.variants)
end

local function position(span)
	for k, v in ipairs(span.vis or {}) do
		if v == span.active then
			return k
		end
	end
	return 1
end

-- Replacing a span's whole text (ga, cycling, and their undo and redo) invalidates its mark, but the text
-- is still in the same place: find which variant sits there and mark it again.
local function revive(buf, id, span)
	local sr, sc, er, ec, invalid = pos(buf, id)
	if not sr or not (invalid or (sr == er and sc == ec)) then
		return
	end
	if er < sr or (er == sr and ec < sc) then
		sr, sc = er, ec -- an invalidated mark can end up inverted; the text starts at the earlier end
	end
	local best
	for _, v in ipairs(span.vis) do
		local lines = vim.split(v.text, "\n", { plain = true })
		local ver, vec = sr + #lines - 1, #lines == 1 and sc + #lines[1] or #lines[#lines]
		local ok, got = pcall(vim.api.nvim_buf_get_text, buf, sr, sc, ver, vec, {})
		if ok and table.concat(got, "\n") == v.text and (not best or #v.text > #best[1].text) then
			best = { v, ver, vec }
		end
	end
	if best then
		span.active = best[1]
		remark(buf, id, sr, sc, best[2], best[3])
	end
end

-- Keeps alternatives in step with edits and with the undo history.
local function sync(buf)
	local cur = changenr(buf)
	local fresh = cur > (newest[buf] or cur) -- a new change, not an undo or a redo
	newest[buf] = math.max(newest[buf] or cur, cur)
	local editing = false
	for _, span in pairs(spans[buf] or {}) do
		editing = editing or span.editing == true
	end
	if fresh and not own and not editing then
		ga_last[buf] = false -- a plain change replaced the ga change as what . repeats
	end
	own = false
	for id, span in pairs(spans[buf] or {}) do
		if not span.editing then
			if fresh then
				-- A change after an undo: undone variants are gone for good, undone drops stay undone.
				span.variants = vim.tbl_filter(function(v)
					return not v.unborn
				end, span.variants)
				for _, v in ipairs(span.variants) do
					v.died = not v.undead and v.died or nil
				end
			end
			span.vis = visible(span, cur)
			revive(buf, id, span)
			local t, found = text(buf, id), nil
			for _, v in ipairs(span.vis) do
				if v.text == t then
					found = v
					break
				end
			end
			if found then
				span.active = found
			elseif t and t ~= "" and #span.vis > 0 then
				if not vim.tbl_contains(span.vis, span.active) then
					span.active = span.vis[#span.vis]
				end
				span.active.text = t
			end
			for _, v in ipairs(span.variants) do
				v.unborn = v.born ~= nil and v.born > cur
				v.undead = v.died ~= nil and cur < v.died
			end
			local sr, sc, er, ec = range(buf, id)
			if #span.variants < 2 then
				remove(buf, id)
			elseif sr and (#span.vis > 1) ~= span.painted then
				span.painted = #span.vis > 1
				remark(buf, id, sr, sc, er, ec)
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
	if not sr or not span.vis or #span.vis < 2 then
		return
	end
	local first, last = vim.fn.screenpos(0, sr + 1, sc + 1), vim.fn.screenpos(0, er + 1, math.max(ec, 1))
	if first.row == 0 or last.row == 0 then
		return
	end
	local lines, width = {}, 0
	for k, v in ipairs(span.vis) do
		lines[k] = (v == span.active and "• " or "  ") .. v.text:gsub("\n", " ⏎ ")
		width = math.max(width, vim.fn.strdisplaywidth(lines[k]))
	end
	local textoff = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff
	width = math.min(width + 1, vim.api.nvim_win_get_width(0) - textoff - 2)
	local row = last.row
	if row + #lines + 2 > vim.o.lines - 1 then
		row = first.row - #lines - 3
	end
	local pbuf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(pbuf, 0, -1, false, lines)
	for k, v in ipairs(span.vis) do
		vim.api.nvim_buf_set_extmark(pbuf, ns, k - 1, 0, { line_hl_group = v == span.active and "Normal" or "InkDim" })
	end
	local win = vim.api.nvim_open_win(pbuf, false, {
		relative = "editor",
		row = row,
		col = math.max(first.col - 4, 0), -- border and marker, so variants line up with the text
		width = width,
		height = #lines,
		style = "minimal",
		border = "rounded",
		title = (" %d/%d "):format(position(span), #span.vis),
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
	local function at(byte) -- byte in the joined text to 0-based row, col
		local row = 1
		while starts[row + 1] and starts[row + 1] <= byte do
			row = row + 1
		end
		return row - 1, byte - starts[row]
	end
	local whole, best, dist = table.concat(lines, "\n"), nil, nil
	local s = whole:find(want, 1, true)
	while s do
		local row, col = at(s)
		if not dist or math.abs(row - (a.row or 0)) < dist then
			local er, ec = at(s + #want)
			best, dist = { row, col, er, ec }, math.abs(row - (a.row or 0))
		end
		s = whole:find(want, s + 1, true)
	end
	if best then
		return unpack(best)
	end
end

-- The footer's "alternatives": put them back on load, list the visible ones on save.
local function load(buf, list)
	spans[buf], lost[buf], newest[buf] = {}, {}, nil
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for _, a in ipairs(type(list) == "table" and list or {}) do
		local sr, sc, er, ec = locate(buf, a)
		if sr then
			local variants = vim.tbl_map(function(t)
				return { text = t }
			end, a.variants)
			local span = { variants = variants, vis = variants, painted = true }
			span.active = variants[(a.active or 0) + 1]
			add_span(buf, sr, sc, er, ec, span)
		else
			table.insert(lost[buf], a)
		end
	end
	if #lost[buf] > 0 then
		echo(("%d set(s) of alternatives no longer match the text; they stay in the file"):format(#lost[buf]))
	end
end

local function dump(buf)
	sync(buf)
	local list = vim.deepcopy(lost[buf] or {})
	for id, span in pairs(spans[buf] or {}) do
		local sr, sc, er, ec = range(buf, id)
		if sr and not span.editing and span.vis and #span.vis > 1 then
			list[#list + 1] = {
				row = sr,
				start_col = sc,
				end_row = er,
				end_col = ec,
				active = position(span) - 1,
				variants = vim.tbl_map(function(v)
					return v.text
				end, span.vis),
			}
		end
	end
	if #list == 0 then
		return nil
	end
	table.sort(list, function(a, b)
		return a.row < b.row or (a.row == b.row and a.start_col < b.start_col)
	end)
	return list
end

-- Insert is over: the span's text is the new variant. Nothing written undoes the whole change.
local function finish(buf, id)
	local span = of(buf)[id]
	if not span then
		return
	end
	span.editing = false
	local result = text(buf, id)
	if not result or result == "" then
		vim.api.nvim_buf_call(buf, function()
			vim.cmd("silent undo " .. (span.born - 1))
		end)
	elseif result ~= span.active.text then
		local v = { text = result, born = span.born }
		table.insert(span.variants, v)
		span.active = v
		ga_last[buf] = true
	end
	local sr, sc, er, ec = range(buf, id)
	if #span.variants < 2 or not sr then
		return remove(buf, id)
	end
	remark(buf, id, sr, sc, er, ec)
	sync(buf)
	pcall(vim.api.nvim__redraw, { statusline = true, flush = true }) -- the ruler shows the new count now
end

-- The change ga started has deleted its text and entered insert: open (or reopen) a span around it.
local function start(buf, p)
	if p.reg == "_" or vim.b[buf].changedtick == p.tick then
		return -- nothing was deleted, or the black hole register ate it
	end
	local old = vim.fn.getreg(p.reg)
	if vim.fn.getregtype(p.reg) == "V" then
		old = old:gsub("\n$", "")
	end
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]
	local id, span = p.id, p.id and of(buf)[p.id]
	local sr, sc, er, ec, invalid
	if span then
		sr, sc, er, ec, invalid = pos(buf, id)
		if invalid or (sr == er and sc == ec) then
			if old ~= span.active.text then
				remove(buf, id) -- the change reached past these alternatives
				span = nil
			else
				sr, sc, er, ec = row, col, row, col
			end
		end
	end
	if span then
		-- This is a new change: whatever was undone before it is gone for good.
		span.variants = vim.tbl_filter(function(v)
			return not v.unborn
		end, span.variants)
		for _, v in ipairs(span.variants) do
			v.died = not v.undead and v.died or nil
		end
	else
		if old == "" then
			return
		end
		sr, sc, er, ec = row, col, row, col
		span = { variants = { { text = old } } }
		span.active = span.variants[1]
		id = add_span(buf, sr, sc, er, ec, span)
		footer.track(buf)
	end
	span.editing, span.painted, span.born = true, true, changenr(buf)
	remark(buf, id, sr, sc, er, ec)
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = util.group,
		buffer = buf,
		callback = function()
			if vim.v.event.old_mode:match("^i") and not vim.v.event.new_mode:match("^i") then
				vim.schedule(function()
					finish(buf, id)
				end)
				return true
			end
		end,
	})
end

-- ga is c that keeps the old text; the mapping only notes where the change starts.
local function arm(buf)
	pending = { buf = buf, id = at_cursor(buf), reg = vim.v.register, tick = vim.b[buf].changedtick }
end

local function cycle(step)
	local buf = vim.api.nvim_get_current_buf()
	local id = at_cursor(buf)
	if not id then
		return
	end
	sync(buf)
	local span = of(buf)[id]
	if not span or #span.vis < 2 then
		return
	end
	span.active = span.vis[(position(span) - 1 + step * vim.v.count1) % #span.vis + 1]
	own = true
	put(buf, id, span.active.text)
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
	echo(("Kept %d of %d"):format(position(span), #span.vis))
end

-- Drops the variant in the text and shows the next one; u brings it back.
local function drop()
	local buf = vim.api.nvim_get_current_buf()
	local id = at_cursor(buf)
	if not id then
		return
	end
	sync(buf)
	local span = of(buf)[id]
	if not span or #span.vis < 2 then
		return
	end
	local gone, k = span.active, position(span)
	span.active = span.vis[k + 1] or span.vis[k - 1]
	own = true
	put(buf, id, span.active.text)
	gone.died = changenr(buf)
	sync(buf)
	if #span.vis > 1 then
		return show_popup(buf, id)
	end
	close_popup()
	echo("Dropped; one variant left, so the alternatives are gone (u brings them back)")
end

-- True while a variant is being typed, so Ink's undo-by-sentence keeps a ga change one undo step.
function M.editing()
	for _, span in pairs(spans[vim.api.nvim_get_current_buf()] or {}) do
		if span.editing then
			return true
		end
	end
	return false
end

-- "2/3 · " while the cursor is in alternatives, for the ruler.
function M.status()
	local buf = vim.api.nvim_get_current_buf()
	local id = next(spans[buf] or {}) and at_cursor(buf)
	local span = id and of(buf)[id]
	if not span or span.editing or not span.vis or #span.vis < 2 then
		return ""
	end
	return ("%d/%d · "):format(position(span), #span.vis)
end

pcall(function()
	require("which-key").add({ { "<leader>v", group = "Alternati[v]es and stash" } })
end)
vim.keymap.set({ "n", "x" }, "ga", function()
	arm(vim.api.nvim_get_current_buf())
	return "c"
end, { expr = true, desc = "Change, keeping the old text as an alternative" })
vim.keymap.set("n", ".", function()
	local buf = vim.api.nvim_get_current_buf()
	if ga_last[buf] then
		arm(buf)
	end
	return "."
end, { expr = true, desc = "Repeat last change (a ga change repeats as ga)" })
vim.keymap.set("n", "]v", function() cycle(1) end, { desc = "Next alternative" })
vim.keymap.set("n", "[v", function() cycle(-1) end, { desc = "Previous alternative" })
vim.keymap.set("n", "<leader>vk", keep, { desc = "Alternatives: keep this one" })
vim.keymap.set("n", "<leader>vd", drop, { desc = "Alternatives: drop this one" })

vim.api.nvim_create_autocmd("InsertEnter", {
	group = util.group,
	callback = function(ev)
		local p = pending
		pending = nil
		if p and p.buf == ev.buf then
			start(ev.buf, p)
		end
	end,
})

-- ga followed by <Esc> or a failed motion: forget it.
vim.api.nvim_create_autocmd("ModeChanged", {
	group = util.group,
	pattern = "no*:n",
	callback = function()
		pending = nil
	end,
})

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
	group = util.group,
	callback = function(ev)
		if next(spans[ev.buf] or {}) or ga_last[ev.buf] then
			sync(ev.buf)
		end
	end,
})

vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
	group = util.group,
	callback = function(ev)
		if popup and (ev.event ~= "CursorMoved" or at_cursor(ev.buf) ~= popup.id) then
			close_popup()
		end
	end,
})

-- Resting on alternatives lists them.
vim.api.nvim_create_autocmd("CursorHold", {
	group = util.group,
	callback = function(ev)
		local id = next(spans[ev.buf] or {}) and at_cursor(ev.buf)
		if id and not (popup and popup.id == id) then
			show_popup(ev.buf, id)
		end
	end,
})

vim.api.nvim_create_autocmd("WinScrolled", {
	group = util.group,
	callback = function()
		if popup then
			show_popup(popup.buf, popup.id)
		end
	end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
	group = util.group,
	callback = function(ev)
		spans[ev.buf], lost[ev.buf], newest[ev.buf], ga_last[ev.buf] = nil, nil, nil, nil
	end,
})

footer.register("alternatives", { load = load, dump = dump })

M.spans, M.ns = spans, ns

return M
