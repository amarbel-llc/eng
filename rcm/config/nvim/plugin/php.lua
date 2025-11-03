
local lspconfig = require("lspconfig")

lspconfig.intelephense.setup({
  settings = {
    intelephense = {
      maxMemory = 8192,
      files = {
        exclude = {
          "**/.git/**",
          "**/node_modules/**",
          "**/htdocs/assets/dist/**",
          "**/tmp/**",
          "translations/**",
          "**/.phan/**",
          "**/generated/**",
          "**/Generated/**",
          "**/vendor/*/{!(phpunit)/**}",
        },
      },
      environment = { phpVersion = "8.2" },
    },
  },
})
