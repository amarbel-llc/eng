return {
	cmd = { "bash-language-server" },

	filetypes = {
		"bash",
		"sh",
	},

	root_dir = function(bufnr, on_dir)
		on_dir(vim.fn.getcwd())
	end,

	root_markers = {
		".envrc",
		".git",
	},
}
