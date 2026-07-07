-- ftplugin/kotlin.lua

local utils = require("sonata_utils")

if utils.is_google3() then
	return
end

local fname = vim.api.nvim_buf_get_name(0)
local sonata_root = utils.find_sonata_root(fname)
local root_dir = nil

if sonata_root then
	root_dir = sonata_root
else
	local fallback = vim.fs.find(
	{ "settings.gradle", "build.gradle", "settings.gradle.kts", "build.gradle.kts", ".git" },
		{ path = fname, upward = true })[1]
	root_dir = fallback and vim.fs.dirname(fallback) or nil
end

if root_dir then
	local build_top = utils.find_android_build_top(fname)
	local cmd = { "kotlin-lsp", "--stdio" }
	if build_top then
		table.insert(cmd, "--system-path")
		table.insert(cmd, build_top .. "/out/gradle/sonata/kotlin-lsp-system")
	end
	vim.lsp.start({
		name = "kotlin-lsp",
		cmd = cmd,
		root_dir = root_dir,
	})
end
