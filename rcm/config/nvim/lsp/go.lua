local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

return {
	cmd = { "gopls" },

	filetypes = { "go" },

	root_markers = {
		"go.mod",
		"go.sum",
		".git",
	},

	-- for postfix snippets and analyzers
	capabilities = capabilities,

	settings = {
		gopls = {
			gofumpt = true,
			experimentalPostfixCompletions = true,
			analyses = {
				unusedparams = true,
				shadow = true,

				-- fuck you, don't tell me how to live
				["ST1000"] = false, -- specifically, package comments
				["ST1003"] = false, -- specifically, underscores package names
				["ST1020"] = false, -- specifically, comments for public functions
				["ST1021"] = false, -- specifically, comments for public types
				["ST1005"] = false, -- error formats
				["ST1006"] = false, -- named return values
			},
			staticcheck = true,
		},
	},
	on_attach = function(client, bufnr)
		-- Disable gopls formatting
		client.server_capabilities.documentFormattingProvider = false

		-- Set up golines formatting
		-- vim.api.nvim_buf_set_option(bufnr, 'equalprg', 'golines --max-len=80 --no-chain-split-dots --shorten-comments --base-formatter=gofumpt %')
	end,
}
