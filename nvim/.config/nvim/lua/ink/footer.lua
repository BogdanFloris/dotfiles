-- lua/ink/footer.lua
-- Ink's per-document state (alternatives, stash) lives in a trailing HTML comment, the format from the
-- Ink Buffer idea doc. It's stripped from the buffer on load and written back on :w, so the buffer never
-- holds it and other tools just see a comment.

local util = require("ink.util")

local M = {}
local MARK = "<!-- ink_buffer"
local parts = {} -- footer key -> { load = fn(buf, value), dump = fn(buf) -> value or nil }
local extra = {} -- per buffer: footer keys no module owns, kept as they were

-- A module owns a footer key: load gets the saved value (nil when there is none), dump returns what to save.
function M.register(key, part)
	parts[key] = part
end

local function lines(buf)
	local data = vim.deepcopy(extra[buf] or {})
	for key, part in pairs(parts) do
		data[key] = part.dump(buf)
	end
	if vim.tbl_isempty(data) then
		return nil
	end
	return { "", MARK, (vim.json.encode(data):gsub("%-%->", "--\\u003e")), "-->" }
end

-- From now on :w writes the buffer plus the footer (or no footer once there's nothing to save).
function M.track(buf)
	if vim.b[buf].ink_footer then
		return
	end
	vim.b[buf].ink_footer = true
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		group = util.group,
		buffer = buf,
		callback = function(ev)
			local out = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			vim.list_extend(out, lines(buf) or {})
			local path = vim.fn.fnamemodify(ev.match, ":p")
			if vim.fn.writefile(out, path) ~= 0 then
				return vim.api.nvim_echo({ { "Ink: could not write " .. path, "ErrorMsg" } }, true, {})
			end
			if path == vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p") then
				vim.bo[buf].modified = false
			end
			vim.api.nvim_echo({ { ('"%s" %dL written'):format(vim.fn.fnamemodify(path, ":~:."), #out), "InkFaint" } }, false, {})
		end,
	})
end

-- Strips the footer on load, without an undo step, and hands each key to its module.
local function read(buf)
	local text = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local n = #text
	while n > 0 and text[n] == "" do
		n = n - 1
	end
	local data
	if n >= 3 and text[n] == "-->" and text[n - 2] == MARK then
		local ok, decoded = pcall(vim.json.decode, text[n - 1])
		if ok and type(decoded) == "table" then
			data = decoded
			local first = (n > 3 and text[n - 3] == "") and n - 3 or n - 2
			local undolevels = vim.bo[buf].undolevels
			vim.bo[buf].undolevels = -1
			vim.api.nvim_buf_set_lines(buf, first - 1, -1, false, {})
			vim.bo[buf].undolevels = undolevels
			vim.bo[buf].modified = false
		end
	end
	for key, part in pairs(parts) do
		part.load(buf, data and data[key])
		if data then
			data[key] = nil
		end
	end
	extra[buf] = data or {}
	if data then
		M.track(buf)
	end
end

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
		extra[ev.buf] = nil
	end,
})

return M
