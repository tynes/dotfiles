local trust = require "config.trust"

---@type vim.lsp.Config
return {
  cmd = { "typescript-language-server", "--stdio" },
  init_options = { hostInfo = "neovim" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_dir = trust.root { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
}
