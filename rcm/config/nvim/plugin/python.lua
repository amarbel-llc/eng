require 'lspconfig'.pylsp.setup {
  cmd = { "pylsp", "-vvv" }, -- verbose logging
  settings = {
    pylsp = {
      plugins = {
        ruff = {
          formatEnabled = true,

          enabled = true,
          -- format = { "I", "F", "UP", "B" },  -- imports, pyflakes, pyupgrade, bugbear
          format = { "I" }, -- imports, pyflakes, pyupgrade, bugbear
          lineLength = 88,
          -- select = { "E", "F", "I" },
          -- ignore = { "E501" },  -- ignore line too long since formatter handles it
          pylsp_mypy = {
            enabled = true,
            live_mode = false,
            overrides = {
              "--explicit-package-bases",
              "--ignore-missing-imports",
            },
          },
        },

        pycodestyle = { enabled = false },
        mccabe = { enabled = false },
        pyflakes = { enabled = false },
        flake8 = { enabled = false },
      }
    }
  },
}
