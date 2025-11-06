return {
	cmd = { "nil" },

	filetypes = { "nix" },

	root_markers = {
		"flake.nix",
		"flake.lock",
		".git",
	},

	settings = {
		["nil"] = {
			formatting = {
				command = { "nixpkgs-fmt" },
			},
		},
	},
}
