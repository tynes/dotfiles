local trust = require "config.trust"

---@type vim.lsp.Config
return {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_dir = trust.root { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
  -- Hover comes from pyright.
  on_attach = function(client) client.server_capabilities.hoverProvider = false end,
}
