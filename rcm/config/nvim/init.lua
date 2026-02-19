vim.cmd("source $HOME/.config/vim/rc_before_plugins.vim")
require("config.lazy")
vim.cmd("source $HOME/.config/vim/rc_after_plugins.vim")
vim.cmd("colorscheme solarized8")

vim.diagnostic.config({
	virtual_text = false,
})

vim.opt.listchars = {
	tab = "  ",
}

vim.cmd[[set completeopt+=menuone,noselect,popup]]
-- vim.lsp.completion.enable({autotrigger=true})

local lsp_util = require("lsp_util")
local conform = require("conform")

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = "*.md",
	command = "set filetype=pandoc",
})

-- require'nvim-treesitter.install'.prefer_git = true

require("nvim-treesitter.configs").setup({
	-- A list of parser names, or "all" (the listed parsers MUST always be installed)
	ensure_installed = {
		"awk",
		"bash",
		"c",
		"css",
		"csv",
		"diff",
		"dockerfile",
		"dot",
		"editorconfig",
		"fish",
		"git_config",
		"git_rebase",
		"gitattributes",
		"gitcommit",
		"gitignore",
		"go",
		"gomod",
		"gosum",
		"gotmpl",
		"gowork",
		"hcl",
		"html",
		"http",
		"ini",
		"java",
		"javascript",
		"jq",
		"json",
		"just",
		"latex",
		"lua",
		"make",
		"markdown",
		"markdown_inline",
		"nix",
		"perl",
		"php",
		"printf",
		"proto",
		"python",
		"query",
		"regex",
		"ruby",
		"rust",
		"scala",
		"scss",
		"sql",
		"strace",
		"swift",
		"tcl",
		"terraform",
		"textproto",
		"toml",
		"tsv",
		"typescript",
		"typst",
		"udev",
		"vhs",
		"vim",
		"vim",
		"vimdoc",
		"xml",
		"yaml",
		"zig",
	},

	-- Install parsers synchronously (only applied to `ensure_installed`)
	sync_install = false,

	-- Automatically install missing parsers when entering buffer
	-- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
	auto_install = true,

	highlight = {
		enable = true,

		-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
		-- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
		-- Using this option may slow down your editor, and you may see some duplicate highlights.
		-- Instead of true it can also be a list of languages
		additional_vim_regex_highlighting = false,
	},
})

vim.keymap.set({ "n", "v" }, "=", function()
	conform.format({ lsp_fallback = true })
end)

vim.api.nvim_create_user_command("ApplyImports", function(opts)
	local client = lsp_util.get_lsp_client()

	local codeActionProvider = (
		client
		and client.server_capabilities
		and client.server_capabilities["codeActionProvider"]
	) or nil

	if codeActionProvider == nil or type(codeActionProvider) ~= "table" then
		return
	end

	local codeActionKinds = codeActionProvider["codeActionKinds"]

	if codeActionKinds == nil then
		return
	end

	if vim.tbl_contains(codeActionKinds, "source.organizeImports") == false then
		return
	end

	local params = vim.lsp.util.make_range_params(0, "utf-8")

	---@diagnostic disable-next-line: inject-field
	params.context = { only = { "source.organizeImports" } }

	-- buf_request_sync defaults to a 1000ms timeout. Depending on your
	-- machine and codebase, you may want longer. Add an additional
	-- argument after params if you find that you have to write the file
	-- twice for changes to be saved.
	-- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
	--
	local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)

	for cid, res in pairs(result or {}) do
		for _, r in pairs(res.result or {}) do
			if r.edit then
				local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
				vim.lsp.util.apply_workspace_edit(r.edit, enc)
			end
		end
	end
end, {})

vim.api.nvim_create_user_command("Format", function(opts)
	vim.cmd("w")
	conform.format({ lsp_fallback = true })
end, {})

vim.api.nvim_create_user_command("ApplyImportsAndFormat", function(opts)
	vim.cmd("w")
	vim.cmd.ApplyImports()
	conform.format({ lsp_fallback = true })
	vim.cmd("w")
end, {})

vim.api.nvim_create_user_command("Test", function(opts)
	-- if #vim.lsp.get_active_clients() == 0 then
	vim.cmd("call TestViaTestPrg()")
	-- else
	--   vim.cmd.echo("'Not implemented'")
	-- end
end, {})

vim.api.nvim_create_user_command("Build", function(opts)
	local client = lsp_util.get_lsp_client()

	if client == nil then
		vim.cmd("make")
	else
		local opts = { severity = "error" }
		local diags = vim.diagnostic.get(nil, opts)

		if #diags > 0 then
			vim.diagnostic.setqflist(opts)
		else
			vim.cmd("echom 'Build succeeded!'")
		end
	end
end, {})

local function set_keymaps(map)
	local opts = { noremap = true, silent = true }
	for i, v in ipairs(map) do
		vim.keymap.set(v[1], v[2], v[3], opts)
	end
end

set_keymaps({
	{ "n", "<leader>f", vim.cmd.ApplyImportsAndFormat },
	{ "n", "<leader>b", vim.cmd.Build },
	{ "n", "<leader>t", vim.cmd.Test },
	{ "n", "<leader>r", vim.lsp.buf.rename },
	{ "n", "<leader>i", vim.lsp.buf.hover },
	{ "n", "<leader>a", vim.lsp.buf.code_action },
	{ "n", "<leader>gd", vim.lsp.buf.definition },
	{ "n", "<leader>gD", vim.lsp.buf.declaration },
	{ "n", "<leader>gi", vim.lsp.buf.implementation },
	{ "n", "<leader>gr", vim.lsp.buf.references },
	{ "n", "<leader>d", vim.diagnostic.open_float },
	{ "n", "[d", vim.diagnostic.goto_prev },
	{ "n", "]d", vim.diagnostic.goto_next },
})

vim.opt.exrc = true -- allow project-local config
vim.opt.secure = true -- restrict unsafe commands in local configs
-- buf_set_keymaps({
--   {'n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>'},
--   {'n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>'},
--   {'n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>'},
--   {'n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>'},
--   {'n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>'},
--   {'n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>'},
-- })
