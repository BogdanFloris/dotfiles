-- ftplugin/java.lua

local utils = require("sonata_utils")

if utils.is_google3() then
	return
end

local fname = vim.api.nvim_buf_get_name(0)
local sonata_root = utils.find_sonata_root(fname)

if sonata_root then
	local status, jdtls = pcall(require, "jdtls")
	if not status then
		vim.notify("nvim-jdtls not found", vim.log.levels.WARN)
		return
	end
	local build_top = utils.find_android_build_top(fname)

	local workspace_dir = build_top .. "/out/gradle/sonata/jdtls-workspace/" .. vim.fn.fnamemodify(build_top, ":t")

	local config = {
		cmd = {
			"jdtls",
			"-data",
			workspace_dir,
		},
		root_dir = sonata_root,
		settings = {
			java = {
				import = {
					gradle = {
						enabled = true,
					},
				},
			},
		},
	}

	jdtls.start_or_attach(config)
end
