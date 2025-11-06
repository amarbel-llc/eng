
local lsp_dir = vim.fn.stdpath("config") .. "/lsp"

for _, file in ipairs(vim.fn.readdir(lsp_dir)) do
  if file:match("%.lua$") then
    vim.lsp.enable(file:gsub("%.lua$", ""))
  end
end
