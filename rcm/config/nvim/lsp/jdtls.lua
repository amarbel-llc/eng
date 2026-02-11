local home = os.getenv("HOME")

return {
	cmd = {
		"jdtls",
		"-configuration",
		home .. "/.cache/jdtls/config",
		"-data",
		home .. "/.cache/jdtls/workspace/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
		"--jvm-arg=-javaagent:" .. home .. "/.local/share/java/lombok.jar",
	},

	filetypes = { "java" },

	root_markers = {
		"pom.xml",
		"build.gradle",
		"build.gradle.kts",
		".git",
	},

	settings = {
		java = {
			signatureHelp = { enabled = true },
			contentProvider = { preferred = "fernflower" },
			completion = {
				favoriteStaticMembers = {
					"org.junit.Assert.*",
					"org.junit.Assume.*",
					"org.junit.jupiter.api.Assertions.*",
					"org.junit.jupiter.api.Assumptions.*",
					"org.junit.jupiter.api.DynamicContainer.*",
					"org.junit.jupiter.api.DynamicTest.*",
					"org.mockito.Mockito.*",
					"org.mockito.ArgumentMatchers.*",
					"org.hamcrest.Matchers.*",
					"org.hamcrest.CoreMatchers.*",
				},
			},
			sources = {
				organizeImports = {
					starThreshold = 9999,
					staticStarThreshold = 9999,
				},
			},
			codeGeneration = {
				toString = {
					template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
				},
			},
		},
	},
}
