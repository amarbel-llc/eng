return {
	settings = {
		workingDirectories = { mode = 'auto' },
		rulesCustomizations = {
			{ rule = 'prettier/prettier', severity = 'off' },
		},
	},
	flags = {
		allow_incremental_sync = false,
		debounce_text_changes = 1000,
	},
}
