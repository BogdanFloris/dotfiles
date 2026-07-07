local M = {}

function M.is_google3()
	local cwd = vim.fn.getcwd()
	return vim.startswith(cwd, "/google/src/cloud/") or vim.startswith(cwd, "/google/gerrit/")
end

function M.find_android_build_top(fname)
	local match = vim.fs.find({ "build/envsetup.sh" }, {
		path = fname,
		upward = true,
		type = "file",
	})[1]
	if match then
		return vim.fs.dirname(vim.fs.dirname(match))
	end
	return nil
end

function M.find_sonata_root(fname)
	local build_top = M.find_android_build_top(fname)
	if build_top then
		local test_sonata = build_top .. "/vendor/unbundled_google/packages/SystemUIGoogle/studio-dev/sonata"
		if vim.fn.isdirectory(test_sonata) == 1 then
			return test_sonata
		end
	end
	return nil
end

return M
