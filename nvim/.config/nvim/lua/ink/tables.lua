-- lua/ink/tables.lua
-- Fitted tables: each pipe table is drawn as virtual lines (no vertical bars, a faint rule under
-- the header, long cells wrapped inside their column so the table fits the text column), and its
-- raw rows are hidden with conceal_lines. The raw markdown comes back while the cursor is inside.

local util = require("ink.util")

local M = {}

local ns = vim.api.nvim_create_namespace("ink_tables")
local query = vim.treesitter.query.parse("markdown", "(pipe_table) @table")
local state_by_buf = {}
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

local function parse(buf)
	local tables = {}
	local ok, parser = pcall(vim.treesitter.get_parser, buf, "markdown")
	if not ok or not parser then
		return tables
	end
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	for _, node in query:iter_captures(parser:parse()[1]:root(), buf) do
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

function M.render(force)
	local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
	if not util.is_text(buf) or vim.bo[buf].filetype ~= "markdown" then
		return
	end
	local state = state_by_buf[buf] or {}
	state_by_buf[buf] = state
	local tick = vim.api.nvim_buf_get_changedtick(buf)
	if state.tick ~= tick then
		state.tables, state.tick, force = parse(buf), tick, true
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
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
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
			vim.api.nvim_buf_set_extmark(buf, ns, t.first, 0, {
				end_row = t.last,
				end_col = #last_line,
				conceal_lines = "",
			})
			vim.api.nvim_buf_set_extmark(buf, ns, anchor, 0, {
				virt_lines = layouts[key],
				virt_lines_above = above,
			})
		end
	end
end

vim.api.nvim_create_autocmd(
	{ "BufWinEnter", "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI", "WinResized", "VimResized" },
	{
		group = util.group,
		callback = function()
			M.render(false)
		end,
	}
)

return M
