local trust = require "config.trust"

---@type vim.lsp.Config
return {
  cmd = { "nomicfoundation-solidity-language-server", "--stdio" },
  filetypes = { "solidity" },
  root_dir = trust.root { "foundry.toml", "hardhat.config.js", "hardhat.config.ts", "remappings.txt", ".git" },
  settings = { solidity = { formatter = "forge" } },
}
