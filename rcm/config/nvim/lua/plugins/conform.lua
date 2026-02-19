return {
	"stevearc/conform.nvim",
	config = function()
		local conform = require("conform")
		local conform_util = require("conform.util")

		conform.setup({
			formatters = {
				ftplugin = function(bufnr)
					local prg = vim.b[bufnr].conform

					if not prg then
						return {}
					end

					return {
						command = prg[1],
						args = conform_util.tbl_slice(prg, 2),
					}
				end,
				pandoc = {
					command = "pandoc",
					args = { "--columns=80", "-f", "markdown", "-t", "markdown" },
					stdin = true,
				},
				php_cs_fixer = {
					command = "php-cs-fixer",
					args = {
						"fix",
						"$FILENAME",
						"--rules=@PSR12,array_indentation,no_whitespace_in_blank_line,blank_line_after_namespace,no_trailing_comma_in_singleline,method_argument_space",
						"--using-cache=no",
					},
				},
				phpcbf = {
					command = "phpcbf",
					args = {
						"--standard=PSR12",
						"--stdin-path=$FILENAME",
						"-",
					},
					stdin = true,
					exit_codes = { 0, 1 },
				},
			},
			formatters_by_ft = {
				bash = { "ftplugin", "shfmt" },
				-- go = { "ftplugin", },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				lua = { "stylua" },
				nix = { "nixfmt-rfc-style", "nixpkgs_fmt", "nixfmt", "alejandra" },
				pandoc = { "pandoc" },
				php = { "php_cs_fixer" },
				python = { "isort", "black" },
				rust = { "rustfmt", lsp_format = "fallback" },
				sh = { "ftplugin", "shfmt" },
				typescript = { "prettierd", "prettier", stop_after_first = true },
			},
		})
	end,
}
