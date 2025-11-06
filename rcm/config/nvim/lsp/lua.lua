return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },

	root_markers = {
		".luarc.json",
		".luarc.jsonc",
		".luacheckrc",
		".stylua.toml",
		"stylua.toml",
		"selene.toml",
		"selene.yml",
		".git",
	},

	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
				path = vim.split(package.path, ";"),
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
				ignoreDir = {
					".direnv/",
				},
				-- library = { vim.fn.getcwd() },
				checkThirdParty = false,
				maxPreload = 1000,
				preloadFileSize = 50,
			},
			telemetry = {
				enable = false,
			},
		},
	},
}
