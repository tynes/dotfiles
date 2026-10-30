local trust = require "config.trust"

-- Noir. Replaces the noir-nvim plugin's `nargo lsp` setup.
---@type vim.lsp.Config
return {
  cmd = { "nargo", "lsp" },
  filetypes = { "noir" },
  root_dir = trust.root { "Nargo.toml" },
}
