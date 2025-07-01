vim.cmd("source $HOME/.config/vim/rc_before_plugins.vim")
require("config.lazy")
vim.cmd("source $HOME/.config/vim/rc_after_plugins.vim")
vim.cmd("colorscheme solarized8")

vim.diagnostic.config({
  virtual_text = false
})

vim.opt.listchars = {
  tab = "  ",
}

local lsp_util = require("lsp_util")

vim.api.nvim_create_user_command(
  'ApplyImports',
  function(opts)
    local client = lsp_util.get_lsp_client()

    if client == nil then
      return
    end

    local caps = client.server_capabilities

    local codeActionProvider = caps["codeActionProvider"]

    if codeActionProvider == nil or type(codeActionProvider) ~= "table" then
      return
    end

    local codeActionKinds = codeActionProvider["codeActionKinds"]

    if codeActionKinds == nil then
      return
    end

    if vim.tbl_contains(codeActionKinds, "source.organizeImports") == false then
      return
    end

    local params = vim.lsp.util.make_range_params()
    params.context = { only = { "source.organizeImports" } }
    -- buf_request_sync defaults to a 1000ms timeout. Depending on your
    -- machine and codebase, you may want longer. Add an additional
    -- argument after params if you find that you have to write the file
    -- twice for changes to be saved.
    -- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
    for cid, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
          vim.lsp.util.apply_workspace_edit(r.edit, enc)
        end
      end
    end
  end,
  {}
)

vim.api.nvim_create_user_command(
  'Format',
  function(opts)
    local tryLspFormat = function()
      local client = lsp_util.get_lsp_client()

      if client == nil then
        return false
      end

      local caps = client.server_capabilities

      if caps["documentFormattingProvider"] ~= true then
        return false
      end

      local cursor = vim.api.nvim_win_get_cursor(0)
      vim.lsp.buf.format { async = false }
      -- TODO take min of last line or cursors
      vim.api.nvim_win_set_cursor(0, cursor)

      return true
    end

    if tryLspFormat() == false then
      vim.cmd("call FormatViaEqualsPrg()")
      -- function! FormatViaEqualsPrg()
      --   cexpr []
      --   w

      --   let save_pos = getpos(".")
      --   normal gg=G
      --   call setpos(".", save_pos)

      --   if v:shell_error
      --     let contents = join(getline(1, '$'), "\n")
      --     undo
      --     :cexpr contents
      --     copen
      --   else
      --     w
      --     ccl
      --   endif
      -- endfunction
    end
  end,
  {}
)

vim.api.nvim_create_user_command(
  'ApplyImportsAndFormat',
  function(opts)
    vim.cmd.ApplyImports()
    vim.cmd.Format()
    vim.cmd("w")
  end,
  {}
)

vim.api.nvim_create_user_command(
  'Test',
  function(opts)
    -- if #vim.lsp.get_active_clients() == 0 then
    vim.cmd("call TestViaTestPrg()")
    -- else
    --   vim.cmd.echo("'Not implemented'")
    -- end
  end,
  {}
)

vim.api.nvim_create_user_command(
  'Build',
  function(opts)
    local client = lsp_util.get_lsp_client()

    if client == nil then
      vim.cmd("make")
    else
      local opts = { severity = "error" }
      local diags = vim.diagnostic.get(nil, opts)

      if #diags > 0 then
        vim.diagnostic.setqflist(opts)
      else
        vim.cmd("echom 'Build succeeded!'")
      end
    end
  end,
  {}
)

local function set_keymaps(map)
  local opts = { noremap = true, silent = true }
  for i, v in ipairs(map) do
    vim.keymap.set(v[1], v[2], v[3], opts)
  end
end

set_keymaps {
  { 'n', '<leader>f',  vim.cmd.ApplyImportsAndFormat },
  { 'n', '<leader>b',  vim.cmd.Build },
  { 'n', '<leader>t',  vim.cmd.Test },
  { 'n', '<leader>r',  vim.lsp.buf.rename },
  { 'n', '<leader>i',  vim.lsp.buf.hover },
  { 'n', '<leader>a',  vim.lsp.buf.code_action },
  { 'n', '<leader>gd', vim.lsp.buf.definition },
  { 'n', '<leader>gD', vim.lsp.buf.declaration },
  { 'n', '<leader>gi', vim.lsp.buf.implementation },
  { 'n', '<leader>gr', vim.lsp.buf.references },
  { 'n', '<leader>d',  vim.diagnostic.open_float },
  { 'n', '[d',         vim.diagnostic.goto_prev },
  { 'n', ']d',         vim.diagnostic.goto_next },
}
-- buf_set_keymaps({
  --   {'n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>'},
  --   {'n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>'},
  --   {'n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>'},
  --   {'n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>'},
  --   {'n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>'},
  --   {'n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>'},
  -- })
