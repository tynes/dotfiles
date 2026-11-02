local trust = require "config.trust"

-- Workspace root: the highest Cargo.toml with a [workspace] table, else the
-- nearest Cargo.toml. Found by reading files rather than running
-- `cargo metadata`, which would run before the trust check (and cargo can be
-- made to run project code through .cargo/config.toml).
local function cargo_root(bufnr)
  local crate = vim.fs.root(bufnr, "Cargo.toml")
  if not crate then return vim.fs.root(bufnr, { "rust-project.json", ".git" }) end
  local root = crate
  for dir in vim.fs.parents(crate .. "/Cargo.toml") do
    local manifest = dir .. "/Cargo.toml"
    if vim.uv.fs_stat(manifest) then
      for _, line in ipairs(vim.fn.readfile(manifest)) do
        if line:match "^%s*%[workspace%]" then
          root = dir
          break
        end
      end
    end
  end
  return root
end

---@type vim.lsp.Config
return {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_dir = function(bufnr, on_dir) trust.gate(bufnr, cargo_root(bufnr), on_dir) end,
  capabilities = { experimental = { serverStatusNotification = true } },
  settings = {
    ["rust-analyzer"] = {
      cargo = { allFeatures = true, buildScripts = { enable = true } },
      procMacro = { enable = true },
      check = { command = "clippy" },
    },
  },
}
