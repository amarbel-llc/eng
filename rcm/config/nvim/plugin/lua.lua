local config_path = vim.fn.stdpath("config")

require('lspconfig').lua_ls.setup({
  root_dir = function()
    return vim.fn.getcwd()
  end,

  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using
        -- (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT'
      },

      workspace = {
        library = { vim.fn.getcwd() },
        checkThirdParty = false,
        maxPreload = 1000,
        preloadFileSize = 50
      }
    }
  }
})

-- require 'lspconfig'.lua_ls.setup {
--   on_init = function(client)
--     local path = client.workspace_folders[1].name

--     if vim.loop.fs_stat(path .. '/.luarc.json') or vim.loop.fs_stat(path .. '/.luarc.jsonc') then
--       return
--     end

--     client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
--       runtime = {
--         -- Tell the language server which version of Lua you're using
--         -- (most likely LuaJIT in the case of Neovim)
--         version = 'LuaJIT'
--       },

--       -- limit to opened files only
--       -- workspace = {
--       --   library = {},
--       --   maxPreload = 0,
--       --   preloadFileSize = 0
--       -- }

--       -- limit to cwd
--       workspace = {
--         checkThirdParty = false,
--         library = {
--           -- vim.fn.getcwd()
--         },
--         maxPreload = 1000,
--         preloadFileSize = 50
--       },

--       -- include Neovim runtime files
--       -- workspace = {
--       --   checkThirdParty = false,
--       --   library = {
--       --     vim.env.VIMRUNTIME
--       --     -- Depending on the usage, you might want to add additional paths here.
--       --     -- "${3rd}/luv/library"
--       --     -- "${3rd}/busted/library",
--       --   }
--       --   -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
--       --   -- library = vim.api.nvim_get_runtime_file("", true)
--       -- }

--     })
--   end,
-- }
