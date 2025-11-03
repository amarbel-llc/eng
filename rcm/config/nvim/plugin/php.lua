vim.lsp.config('phpactor', {
  init_options = {
    ["language_server_php_cs_fixer.enabled"] = true,
    ["language_server_php_cs_fixer.bin"] = vim.fn.exepath("php-cs-fixer"),
  }
}
