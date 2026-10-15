-- lua/ink/stash.lua
-- The stash: text cut from the draft that you might want back, kept with the document. gs works like d
-- (gsis, gsip, gss, visual gs) but the text goes onto the stash; <leader>vs picks something to put back
-- at the cursor, the way p would. Both are single undo steps, so u and <C-r> move text back and forth.

local footer = require("ink.footer")
local util = require("ink.util")

local M = {}
local items = {} -- items[buf] = { { text, linewise, born?, died? }, ... }, oldest first
local newest = {} -- per buffer: the highest change number seen, to tell new changes from undo and redo

local function of(buf)
	items[buf] = items[buf] or {}
	return items[buf]
end

local function echo(msg)
	vim.api.nvim_echo({ { msg, "InkFaint" } }, false, {})
end

local function changenr(buf)
	return vim.api.nvim_buf_call(buf, vim.fn.changenr)
end

-- The items that exist at this point of the undo history.
local function shown(buf)
	local cur = changenr(buf)
	return vim.tbl_filter(function(it)
		return (not it.born or it.born <= cur) and (not it.died or cur < it.died)
	end, of(buf))
end

-- A new change after an undo makes the undone stashing (or taking back) permanent.
local function sync(buf)
	local cur = changenr(buf)
	local fresh = cur > (newest[buf] or cur)
	newest[buf] = math.max(newest[buf] or cur, cur)
	if fresh then
		items[buf] = vim.tbl_filter(function(it)
			return not it.unborn
		end, of(buf))
		for _, it in ipairs(items[buf]) do
			it.died = not it.undead and it.died or nil
		end
	end
	for _, it in ipairs(of(buf)) do
		it.unborn = it.born ~= nil and it.born > cur
		it.undead = it.died ~= nil and cur < it.died
	end
end

local function refresh_ruler()
	pcall(vim.api.nvim__redraw, { statusline = true, flush = true })
end

-- The operator function behind gs: cuts the motion's text with one undoable change.
function M.op(kind)
	local buf = vim.api.nvim_get_current_buf()
	local s, e = vim.api.nvim_buf_get_mark(buf, "["), vim.api.nvim_buf_get_mark(buf, "]")
	local sr, sc, er, ec = s[1] - 1, s[2], e[1] - 1, e[2]
	local text
	if kind == "line" then
		text = table.concat(vim.api.nvim_buf_get_lines(buf, sr, er + 1, false), "\n")
	elseif kind == "char" then
		local last = vim.api.nvim_buf_get_lines(buf, er, er + 1, false)[1]
		ec = #last == 0 and 0 or math.min(ec, #last - 1)
		ec = #last == 0 and 0 or ec + vim.str_utf_end(last, ec + 1) + 1 -- ']' marks the last character
		text = table.concat(vim.api.nvim_buf_get_text(buf, sr, sc, er, ec, {}), "\n")
	else
		return echo("The stash takes characters or lines, not blocks")
	end
	if not text:find("%S") then
		return
	end
	if kind == "line" then
		vim.api.nvim_buf_set_lines(buf, sr, er + 1, false, {})
		local row = math.min(sr + 1, vim.api.nvim_buf_line_count(buf))
		vim.api.nvim_win_set_cursor(0, { row, 0 })
	else
		vim.api.nvim_buf_set_text(buf, sr, sc, er, ec, {})
		vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
	end
	table.insert(of(buf), { text = text, linewise = kind == "line", born = changenr(buf) })
	footer.track(buf)
	refresh_ruler()
end

-- Puts an item back at the cursor the way p would, and takes it off the stash (u reverses both).
function M.pop(buf, item)
	vim.api.nvim_put(vim.split(item.text, "\n", { plain = true }), item.linewise and "l" or "c", true, true)
	item.died = changenr(buf)
	refresh_ruler()
end

local function discard(buf, item)
	for i, it in ipairs(of(buf)) do
		if it == item then
			table.remove(items[buf], i)
			break
		end
	end
	refresh_ruler()
end

-- Lists the stash, newest first, in fzf-lua (vim.ui.select without it).
local function pick()
	local buf = vim.api.nvim_get_current_buf()
	sync(buf)
	local list = shown(buf)
	if #list == 0 then
		return echo("The stash is empty")
	end
	local ok, fzf = pcall(require, "fzf-lua")
	if not ok then
		return vim.ui.select(list, {
			prompt = "Stash",
			format_item = function(it)
				return (it.text:gsub("\n", " ⏎ "))
			end,
		}, function(it)
			if it then
				M.pop(buf, it)
			end
		end)
	end
	local entries = {}
	for i = #list, 1, -1 do
		entries[#entries + 1] = ("%d\t%s%s"):format(i, list[i].linewise and "¶ " or "", (list[i].text:gsub("\n", " ⏎ ")))
	end
	local function chosen(selected)
		local i = selected and selected[1] and tonumber(selected[1]:match("^(%d+)\t"))
		return i and list[i]
	end
	fzf.fzf_exec(entries, {
		prompt = "Stash> ",
		fzf_opts = {
			["--delimiter"] = "\t",
			["--with-nth"] = "2..",
			["--no-multi"] = true,
			["--header"] = "enter: put back at the cursor · ctrl-x: discard",
		},
		actions = {
			["default"] = function(selected)
				local it = chosen(selected)
				if it then
					M.pop(buf, it)
				end
			end,
			["ctrl-x"] = function(selected)
				local it = chosen(selected)
				if it then
					discard(buf, it)
				end
			end,
		},
	})
end

-- "3 stashed · " for the ruler while the stash holds something.
function M.status()
	local buf = vim.api.nvim_get_current_buf()
	if not items[buf] or #items[buf] == 0 then
		return ""
	end
	local n = #shown(buf)
	return n > 0 and ("%d stashed · "):format(n) or ""
end

local function operator(motion)
	return function()
		vim.o.operatorfunc = "v:lua.require'ink.stash'.op"
		return "g@" .. (motion or "")
	end
end

vim.keymap.set({ "n", "x" }, "gs", operator(), { expr = true, desc = "Stash: cut onto the document's stash, like d" })
vim.keymap.set("n", "gss", operator("_"), { expr = true, desc = "Stash the line" })
vim.keymap.set("n", "<leader>vs", pick, { desc = "Stash: put something back" })

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
	group = util.group,
	callback = function(ev)
		if items[ev.buf] and #items[ev.buf] > 0 then
			sync(ev.buf)
		end
	end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
	group = util.group,
	callback = function(ev)
		items[ev.buf], newest[ev.buf] = nil, nil
	end,
})

footer.register("stash", {
	load = function(buf, list)
		items[buf], newest[buf] = {}, nil
		for _, it in ipairs(type(list) == "table" and list or {}) do
			it = type(it) == "string" and { text = it } or it
			if type(it) == "table" and type(it.text) == "string" then
				table.insert(items[buf], { text = it.text, linewise = it.linewise == true })
			end
		end
	end,
	dump = function(buf)
		sync(buf)
		local list = vim.tbl_map(function(it)
			return { text = it.text, linewise = it.linewise or nil }
		end, shown(buf))
		return #list > 0 and list or nil
	end,
})

M.items = items

return M
