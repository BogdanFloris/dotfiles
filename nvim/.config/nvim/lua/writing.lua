-- lua/writing.lua
-- The writing room. Loaded only when Neovim is started by `ink` (see ink/.local/bin/ink).

vim.env.INK_WRITING = nil

local c = {
	bg = "#32302f",
	fg = "#ebdbb2",
	bright = "#fbf1c7",
	dim = "#7c6f64",
	faint = "#665c54",
	yellow = "#fabd2f",
	blue = "#83a598",
	aqua = "#8ec07c",
}

require("gruvbox").setup({
	inverse = true,
	contrast = "soft",
	overrides = {
		InkDim = { fg = c.dim },
		InkFaint = { fg = c.faint },
		InkMargin = { fg = c.dim, bg = c.bg },
		InkText = { fg = c.fg },
		InkTableHead = { fg = c.bright, bold = true },
		InkBold = { fg = c.bright, bold = true },
		InkCode = { fg = c.aqua },
		InkLink = { fg = c.blue, underline = true },
		-- Hides smoothscroll's "<<<" on a partly scrolled first line.
		NonText = { fg = c.bg },
		["@markup.heading"] = { fg = c.yellow, bold = true },
		["@markup.strong"] = { fg = c.bright, bold = true },
		["@markup.link.label"] = { fg = c.blue, underline = true },
		["@punctuation.special.markdown"] = { fg = c.faint },
		-- Inline code as plain colored text, without render-markdown's background patches.
		["@markup.raw.markdown_inline"] = { fg = c.aqua },
		RenderMarkdownCodeInline = { fg = c.aqua },
		RenderMarkdownBullet = { fg = c.dim },
	},
})

-- setup() replaces the config from plugins.lua, so its base options are repeated here.
-- Heading markers are concealed in the text and drawn in the left margin instead (ink_margin).
-- Tables are drawn by Ink itself (see fitted tables below), so render-markdown's renderer is off.
require("render-markdown").setup({
	render_modes = true,
	anti_conceal = { enabled = false },
	win_options = { concealcursor = { rendered = "nvic" } },
	heading = { sign = false, icons = { "" }, position = "inline", backgrounds = {} },
	link = { enabled = false },
	pipe_table = { enabled = false },
	code = { sign = false },
})

-- Ink runs outside herdr, so the clipboard can be read straight from Ghostty (clipboard-read = allow).
local osc52 = require("vim.ui.clipboard.osc52")
vim.g.clipboard = {
	name = "OSC 52",
	copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
	paste = { ["+"] = osc52.paste("+"), ["*"] = osc52.paste("*") },
}
vim.keymap.set("i", "<C-v>", "<C-r><C-o>+")

vim.g.loaded_dropbar = true
vim.g.snacks_indent = false
vim.g.snacks_scope = false
vim.g.minicompletion_disable = true
vim.diagnostic.enable(false)
-- Zen is the room itself; toggling it off would quit (see on_close below).
vim.keymap.set({ "n", "t" }, "<leader>zm", "<Nop>")

vim.o.laststatus = 0
vim.o.showtabline = 0
vim.o.showmode = false
vim.o.showcmd = false
vim.o.ruler = true
vim.o.rulerformat = "%=%#InkFaint#%{wordcount().words} words"
vim.o.number = false
vim.o.relativenumber = false
vim.o.signcolumn = "no"
vim.o.linebreak = true
vim.o.breakindentopt = "list:-1"
vim.o.smoothscroll = true
vim.opt.fillchars:append({ eob = " ", lastline = " " })

local group = vim.api.nvim_create_augroup("ink", { clear = true })
local focus_ns = vim.api.nvim_create_namespace("ink_focus")

local function is_text(buf)
	return vim.bo[buf].buftype == "" and vim.api.nvim_buf_is_loaded(buf)
end

-- Dims everything outside the paragraph under the cursor.
local function focus()
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(buf, focus_ns, 0, -1)
	if not is_text(buf) then
		return
	end
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local function blank(i)
		return lines[i]:match("^%s*$") ~= nil
	end
	local first = vim.api.nvim_win_get_cursor(0)[1]
	local last = first
	if not blank(first) then
		while first > 1 and not blank(first - 1) do
			first = first - 1
		end
		while last < #lines and not blank(last + 1) do
			last = last + 1
		end
	end
	local function dim(from, to)
		vim.api.nvim_buf_set_extmark(buf, focus_ns, from - 1, 0, {
			end_row = to - 1,
			end_col = #lines[to],
			hl_group = "InkDim",
			priority = 10000,
		})
	end
	if first > 1 then
		dim(1, first - 1)
	end
	if last < #lines then
		dim(last + 1, #lines)
	end
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI" }, {
	group = group,
	callback = focus,
})

-- Heading markers hang in a 4-column left margin, iA Writer style.
local heading_marks = {}
local heading_query = vim.treesitter.query.parse("markdown", "(atx_heading) @heading")

local function scan_headings(buf)
	local marks = {}
	local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
	if ok and parser then
		for _, node in heading_query:iter_captures(parser:parse()[1]:root(), buf) do
			local row = node:start()
			marks[row + 1] = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]:match("^#+")
		end
	end
	heading_marks[buf] = marks
end

function _G.ink_margin()
	local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
	local marks = vim.v.virtnum == 0 and (heading_marks[buf] or {})[vim.v.lnum]
	if not marks then
		return "%#InkMargin#    "
	end
	return "%#InkMargin#" .. (#marks <= 3 and string.format("%3s ", marks) or ("#" .. #marks .. "  "))
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI" }, {
	group = group,
	callback = function(ev)
		if is_text(ev.buf) and vim.bo[ev.buf].filetype == "markdown" then
			scan_headings(ev.buf)
		end
	end,
})

-- Fitted tables: each pipe table is drawn as virtual lines (no vertical bars, a faint rule under
-- the header, long cells wrapped inside their column so the table fits the text column), and its
-- raw rows are hidden with conceal_lines. The raw markdown comes back while the cursor is inside.
local table_ns = vim.api.nvim_create_namespace("ink_tables")
local table_query = vim.treesitter.query.parse("markdown", "(pipe_table) @table")
local table_state = {}
local layouts = {} -- "width|table source" -> virtual lines, so typing elsewhere doesn't re-layout
local gap = 2

local function split_row(line)
	line = vim.trim(line):gsub("^|", ""):gsub("([^\\])|$", "%1")
	local cells, cell, i = {}, "", 1
	while i <= #line do
		local ch = line:sub(i, i)
		if ch == "\\" and line:sub(i + 1, i + 1) == "|" then
			cell, i = cell .. "\\|", i + 2
		elseif ch == "|" then
			cells[#cells + 1], cell, i = vim.trim(cell), "", i + 1
		else
			cell, i = cell .. ch, i + 1
		end
	end
	cells[#cells + 1] = vim.trim(cell)
	return cells
end

-- Turns a cell's inline markdown into { char, highlight } pairs, dropping the markup.
local function cell_chars(text, base)
	local out = {}
	local function push(s, hl)
		for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
			out[#out + 1] = { ch, hl }
		end
	end
	local i = 1
	while i <= #text do
		local ch = text:sub(i, i)
		local close = ch == "`" and text:find("`", i + 1, true)
			or text:sub(i, i + 1) == "**" and text:find("**", i + 2, true)
		local label, stop = nil, nil
		if ch == "[" then
			label, stop = text:match("^%[([^%]]*)%]%([^)]*%)()", i)
		end
		if ch == "\\" and i < #text then
			push(text:sub(i + 1, i + 1), base)
			i = i + 2
		elseif ch == "`" and close then
			push(text:sub(i + 1, close - 1), "InkCode")
			i = close + 1
		elseif ch == "*" and close then
			push(text:sub(i + 2, close - 1), "InkBold")
			i = close + 2
		elseif label then
			push(label, "InkLink")
			i = stop
		else
			local j = text:find("[\\`*%[]", i + 1) or #text + 1
			push(text:sub(i, j - 1), base)
			i = j
		end
	end
	return out
end

local function wrap(chars, width)
	local lines, line, used = {}, {}, 0
	local word, word_width, space_hl = {}, 0, nil
	local function flush()
		if #word == 0 then
			return
		end
		if used > 0 and used + 1 + word_width > width then
			lines[#lines + 1], line, used = line, {}, 0
		end
		if used > 0 then
			line[#line + 1], used = { " ", space_hl }, used + 1
		end
		local start = #line + 1 -- where this word begins on the line
		for _, cw in ipairs(word) do
			local w = vim.api.nvim_strwidth(cw[1])
			if used + w > width and used > 0 then
				-- The word is longer than the column: break after its last / _ - . if it has one.
				local carry = {}
				for k = #line, start, -1 do
					if line[k][1]:match("[/_%-%.]") then
						carry = vim.list_slice(line, k + 1)
						for _ = k + 1, #line do
							table.remove(line)
						end
						break
					end
				end
				lines[#lines + 1], line, used, start = line, carry, 0, 1
				for _, moved in ipairs(carry) do
					used = used + vim.api.nvim_strwidth(moved[1])
				end
			end
			line[#line + 1], used = cw, used + w
		end
		word, word_width = {}, 0
	end
	for _, cw in ipairs(chars) do
		if cw[1] == " " then
			flush()
			space_hl = cw[2]
		else
			word[#word + 1], word_width = cw, word_width + vim.api.nvim_strwidth(cw[1])
		end
	end
	flush()
	lines[#lines + 1] = line
	return lines
end

-- Column widths: natural widths if they fit. Otherwise short columns (labels, numbers) keep their
-- natural width and the long ones share the rest, weighted by the square root of their natural
-- width, never below their longest word (capped at 16) unless nothing fits.
local function fit(natural, minimum, available)
	local n, total, reserve, widths = #natural, 0, 0, {}
	for j = 1, n do
		total, reserve = total + natural[j], reserve + minimum[j]
	end
	if total <= available then
		return vim.deepcopy(natural)
	end
	if reserve >= available then
		for j = 1, n do
			widths[j] = math.min(natural[j], math.max(1, math.floor(available / n)))
		end
		return widths
	end
	local order, fixed, used = {}, {}, 0
	for j = 1, n do
		order[j] = j
	end
	table.sort(order, function(a, b)
		return natural[a] < natural[b]
	end)
	local cap = math.floor(available * 0.35)
	for _, j in ipairs(order) do
		if natural[j] <= cap and used + natural[j] + reserve - minimum[j] <= available then
			widths[j], fixed[j] = natural[j], true
			used, reserve = used + natural[j], reserve - minimum[j]
		end
	end
	local rest, weight, given = available - used, 0, 0
	for j = 1, n do
		if not fixed[j] then
			weight = weight + math.sqrt(natural[j])
		end
	end
	for j = 1, n do
		if not fixed[j] then
			local share = math.floor(rest * math.sqrt(natural[j]) / weight)
			widths[j] = math.max(minimum[j], math.min(natural[j], share))
			given = given + widths[j]
		end
	end
	for _ = 1, rest - given do
		local best, most = nil, 0
		for j = 1, n do
			if not fixed[j] and natural[j] - widths[j] > most then
				best, most = j, natural[j] - widths[j]
			end
		end
		if not best then
			break
		end
		widths[best] = widths[best] + 1
	end
	return widths
end

local function layout(t, width)
	local rows, cells, natural, minimum = { t.header }, {}, {}, {}
	vim.list_extend(rows, t.body)
	for i, row in ipairs(rows) do
		cells[i] = {}
		for j = 1, #t.header do
			local chars = cell_chars(row[j] or "", i == 1 and "InkTableHead" or "InkText")
			local total, run, longest = 0, 0, 0
			for _, cw in ipairs(chars) do
				local w = vim.api.nvim_strwidth(cw[1])
				total, run = total + w, cw[1] == " " and 0 or run + w
				longest = math.max(longest, run)
			end
			cells[i][j] = chars
			-- Headers may wrap, so only body cells set a column's natural width.
			if i > 1 or #rows == 1 then
				natural[j] = math.max(natural[j] or 1, total)
			end
			minimum[j] = math.max(minimum[j] or 1, math.min(longest, 16))
		end
	end
	for j = 1, #t.header do
		natural[j] = math.max(natural[j] or 1, minimum[j])
	end
	local widths = fit(natural, minimum, width - gap * (#t.header - 1))
	local out = {}
	local function emit(i)
		local wrapped, height = {}, 1
		for j, w in ipairs(widths) do
			wrapped[j] = wrap(cells[i][j], w)
			height = math.max(height, #wrapped[j])
		end
		for k = 1, height do
			local chunks = {}
			for j, w in ipairs(widths) do
				local piece, used = wrapped[j][k] or {}, 0
				for _, cw in ipairs(piece) do
					used = used + vim.api.nvim_strwidth(cw[1])
				end
				local pad = w - used
				local left = t.align[j] == "right" and pad or t.align[j] == "center" and math.floor(pad / 2) or 0
				local lead = (j > 1 and gap or 0) + left
				if lead > 0 then
					chunks[#chunks + 1] = { string.rep(" ", lead) }
				end
				for _, cw in ipairs(piece) do
					local last = chunks[#chunks]
					if last and last[2] == cw[2] then
						last[1] = last[1] .. cw[1]
					else
						chunks[#chunks + 1] = { cw[1], cw[2] }
					end
				end
				if j < #widths and pad - left > 0 then
					chunks[#chunks + 1] = { string.rep(" ", pad - left) }
				end
			end
			out[#out + 1] = chunks
		end
	end
	emit(1)
	local rule = gap * (#widths - 1)
	for _, w in ipairs(widths) do
		rule = rule + w
	end
	out[#out + 1] = { { string.rep("─", rule), "InkFaint" } }
	for i = 2, #rows do
		emit(i)
	end
	return out
end

local function parse_tables(buf)
	local tables = {}
	local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
	if not ok or not parser then
		return tables
	end
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	for _, node in table_query:iter_captures(parser:parse()[1]:root(), buf) do
		local first, _, last, last_col = node:range()
		if last_col == 0 then
			last = last - 1
		end
		-- Only top-level tables written with leading pipes; anything else stays raw.
		if last > first and lines[first + 1]:match("^|") then
			local t = { first = first, last = last, header = split_row(lines[first + 1]), body = {}, align = {} }
			t.key = table.concat(lines, "\n", first + 1, last + 1)
			for j, d in ipairs(split_row(lines[first + 2])) do
				t.align[j] = d:match("^:.*:$") and "center" or d:match(":$") and "right" or "left"
			end
			for r = first + 3, last + 1 do
				t.body[#t.body + 1] = split_row(lines[r])
			end
			tables[#tables + 1] = t
		end
	end
	return tables
end

local function render_tables(force)
	local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
	if not is_text(buf) or vim.bo[buf].filetype ~= "markdown" then
		return
	end
	local state = table_state[buf] or {}
	table_state[buf] = state
	local tick = vim.api.nvim_buf_get_changedtick(buf)
	if state.tick ~= tick then
		state.tables, state.tick, force = parse_tables(buf), tick, true
	end
	local width = vim.api.nvim_win_get_width(win) - vim.fn.getwininfo(win)[1].textoff
	local row, inside = vim.api.nvim_win_get_cursor(win)[1] - 1, nil
	for i, t in ipairs(state.tables) do
		if row >= t.first and row <= t.last then
			inside = i
		end
	end
	if not force and inside == state.inside and width == state.width then
		return
	end
	state.inside, state.width = inside, width
	vim.api.nvim_buf_clear_namespace(buf, table_ns, 0, -1)
	local count = vim.api.nvim_buf_line_count(buf)
	for i, t in ipairs(state.tables) do
		local anchor, above = t.first - 1, false
		if anchor < 0 then
			anchor, above = t.last + 1, true
		end
		if i ~= inside and anchor < count then
			local key = width .. "|" .. t.key
			if not layouts[key] then
				if vim.tbl_count(layouts) > 200 then
					layouts = {}
				end
				layouts[key] = layout(t, width)
			end
			local last_line = vim.api.nvim_buf_get_lines(buf, t.last, t.last + 1, false)[1]
			vim.api.nvim_buf_set_extmark(buf, table_ns, t.first, 0, {
				end_row = t.last,
				end_col = #last_line,
				conceal_lines = "",
			})
			vim.api.nvim_buf_set_extmark(buf, table_ns, anchor, 0, {
				virt_lines = layouts[key],
				virt_lines_above = above,
			})
		end
	end
end

vim.api.nvim_create_autocmd(
	{ "BufWinEnter", "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI", "WinResized", "VimResized" },
	{
		group = group,
		callback = function()
			render_tables(false)
		end,
	}
)

-- Typewriter scrolling: the line being written stays mid-screen.
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
	group = group,
	callback = function(ev)
		if is_text(ev.buf) then
			-- :normal steps the cursor back off the end of the line in insert mode, so restore it.
			local cursor = vim.api.nvim_win_get_cursor(0)
			vim.cmd("normal! zz")
			vim.api.nvim_win_set_cursor(0, cursor)
		end
	end,
})

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "FocusLost" }, {
	group = group,
	callback = function(ev)
		if is_text(ev.buf) and vim.bo[ev.buf].modified and vim.api.nvim_buf_get_name(ev.buf) ~= "" then
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
		render_tables(true)
	end
end, { desc = "Toggle full-width layout (wide tables)" })

vim.api.nvim_create_autocmd("VimEnter", {
	group = group,
	once = true,
	callback = function()
		text_width = measure(vim.api.nvim_get_current_buf())
		room = Snacks.zen({
			toggles = { dim = false, git_signs = false, mini_diff_signs = false },
			win = {
				width = text_width + margin,
				wo = { statuscolumn = "%!v:lua.ink_margin()" },
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
		render_tables(true)
		vim.cmd("startinsert!")
	end,
})
