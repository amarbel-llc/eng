return {
	cmd = { "intelephense", "--stdio", },

	filetypes = { "php" },

  settings = {
    intelephense = {
      stubs = {
        "Core",
        "Reflection",
        "SPL",
        "composer",
        "date",
        "json",
        "pcre",
        "standard",
      },
      files = {
        associations = { "*.php", "*.phtml" },
      },
      environment = {
        includePaths = { "vendor" },
        phpVersion = "8.2", -- your PHP version
      }
    }
  }
	-- settings = {
	-- 	intelephense = {
	-- 		maxMemory = 8192,
	-- 		files = {
	-- 			exclude = {
	-- 				"**/.git/**",
	-- 				"**/node_modules/**",
	-- 				"**/htdocs/assets/dist/**",
	-- 				"**/tmp/**",
	-- 				"translations/**",
	-- 				"**/.phan/**",
	-- 				"**/generated/**",
	-- 				"**/Generated/**",
	-- 				"**/vendor/*/{!(phpunit)/**}",
	-- 			},
	-- 		},
	-- 		environment = { phpVersion = "8.2" },
	-- 	},
	-- },
}
