local MiniDiff = require("mini.diff")
local DiffSource = {}
local cache = {}
local uv = vim.uv or vim.loop

local function invalidate_cache(c)
	if not c then return end
	if c.fs_event then pcall(c.fs_event.stop, c.fs_event); pcall(c.fs_event.close, c.fs_event) end
	if c.timer then pcall(c.timer.stop, c.timer); pcall(c.timer.close, c.timer) end
end

local set_ref_text = vim.schedule_wrap(function(buf_id, text)
	if not vim.api.nvim_buf_is_valid(buf_id) then return end
	local state = vim.b[buf_id].diff_source or {}
	state.ref_text = text
	vim.b[buf_id].diff_source = state
	MiniDiff.set_ref_text(buf_id, text)
end)

local function debounce(ms, fn)
	local timer = uv.new_timer()
	return function(...)
		local argv = { ... }
		local argc = select("#", ...)
		timer:stop()
		timer:start(ms, 0, function() fn(unpack(argv, 1, argc)) end)
	end, timer
end

local function setup_watch(buf_id, path, watch_path, update_fn)
	local fs_event = uv.new_fs_event()
	if not fs_event then return end

	local debounced_update, timer = debounce(50, function()
		update_fn(path, function(text) set_ref_text(buf_id, text) end)
	end)

	debounced_update()

	if vim.fn.isdirectory(watch_path.root) == 1 then
		fs_event:start(watch_path.root, {}, function(err, filename)
			if err then return end
			if not watch_path.file or not filename or filename == watch_path.file then
				debounced_update()
			end
		end)
	end

	local cur = cache[buf_id] or {}
	invalidate_cache(cur)
	cur.fs_event = fs_event
	cur.timer = timer
	cache[buf_id] = cur
end

local function to_lines(str)
	local lines = vim.split(str or "", "\n", { plain = true })
	if #lines > 0 and lines[#lines] == "" then
		table.remove(lines, #lines)
	end
	return lines
end

local function jj_check_path(name, path)
	local dir = vim.fs.dirname(path)
	if vim.fn.isdirectory(dir) ~= 1 then return nil end
	return {
		cmd = { name, "--ignore-working-copy", "root" },
		cwd = dir,
	}, function(stdout)
		local root = vim.split(stdout, "\n")[1]
		return { root = root .. "/.jj/working_copy", file = "checkout" }
	end
end

local function jj_get_base_text(name, path)
	local dir, basename = vim.fs.dirname(path), vim.fs.basename(path)
	if vim.fn.isdirectory(dir) ~= 1 then return nil end
	return {
		cmd = { name, "--ignore-working-copy", "file", "show", "--no-pager", "-r", "@-", "--", basename },
		cwd = dir,
	}
end

local function hg_check_path(name, path)
	local dir = vim.fs.dirname(path)
	if vim.fn.isdirectory(dir) ~= 1 then return nil end
	return {
		cmd = { name, "--pager", "never", "--color", "never", "root" },
		cwd = dir,
	}, function(stdout)
		local root = vim.split(stdout, "\n")[1]
		return { root = root .. "/.hg", file = "dirstate" }
	end
end

local function hg_get_base_text(name, path)
	local dir, basename = vim.fs.dirname(path), vim.fs.basename(path)
	if vim.fn.isdirectory(dir) ~= 1 then return nil end
	return {
		cmd = { name, "cat", "--rev", ".", "--", basename },
		cwd = dir,
	}
end

local function p4_check_path(name, path)
	local dir = vim.fs.dirname(path)
	if vim.fn.isdirectory(dir) ~= 1 then return nil end
	return {
		cmd = { name, "status" },
		cwd = dir,
	}, function(_)
		local root = path:gsub("^(/google/src/cloud/[^/]+/[^/]+).*$", "%1")
		return { root = root .. "/.citc", file = "srcfs_workspace" }
	end
end

local function p4_get_base_text(name, path)
	local dir, basename = vim.fs.dirname(path), vim.fs.basename(path)
	if vim.fn.isdirectory(dir) ~= 1 then return nil end
	return {
		cmd = { name, "print", "-q", basename },
		cwd = dir,
	}
end

local function create_diff_source(name, check_fn, base_text_fn)
	return function()
		if vim.fn.executable(name) == 0 then
			return { name = name, attach = function(buf) MiniDiff.fail_attach(buf) end, detach = function() end }
		end

		return {
			name = name,
			attach = function(buf_id)
				local path = vim.api.nvim_buf_get_name(buf_id)
				if not path or #path == 0 then return false end

				local syscmd, to_watch_path = check_fn(name, path)
				if not syscmd then
					MiniDiff.fail_attach(buf_id)
					return
				end

				vim.system(syscmd.cmd, { cwd = syscmd.cwd, text = true }, function(out)
					if out.code ~= 0 then
						vim.schedule(function() MiniDiff.fail_attach(buf_id) end)
						return
					end

					local watch_path = to_watch_path(out.stdout or "")
					local update_fn = function(p, set_text)
						local cmd = base_text_fn(name, p)
						if not cmd then return end
						vim.system(cmd.cmd, { cwd = cmd.cwd, text = true }, function(res)
							if res.code == 0 then
								set_text(to_lines(res.stdout or ""))
							else
								set_text({ "" })
							end
						end)
					end

					vim.schedule(function()
						if not vim.api.nvim_buf_is_valid(buf_id) then return end
						setup_watch(buf_id, path, watch_path, update_fn)
					end)
				end)
			end,
			detach = function(buf_id)
				if cache[buf_id] then
					invalidate_cache(cache[buf_id])
					cache[buf_id] = nil
				end
			end,
		}
	end
end

DiffSource.jj = create_diff_source("jj", jj_check_path, jj_get_base_text)
DiffSource.hg = create_diff_source("hg", hg_check_path, hg_get_base_text)
DiffSource.p4 = create_diff_source("p4", p4_check_path, p4_get_base_text)

DiffSource.full_window_diff = function()
	local buf_id = vim.api.nvim_get_current_buf()
	local base_text = (vim.b[buf_id].diff_source or {}).ref_text or {}
	local base_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(base_buf, 0, -1, false, base_text)
	vim.bo[base_buf].buftype = "nofile"
	vim.bo[base_buf].bufhidden = "wipe"
	vim.bo[base_buf].filetype = vim.bo[buf_id].filetype
	vim.bo[base_buf].readonly = true
	vim.bo[base_buf].modifiable = false

	vim.cmd.tabnew()
	local left_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(left_win, base_buf)

	local right_win = vim.api.nvim_open_win(buf_id, true, {
		split = "right",
		win = left_win,
	})

	vim.api.nvim_win_call(left_win, vim.cmd.diffthis)
	vim.api.nvim_win_call(right_win, vim.cmd.diffthis)
end

return DiffSource
