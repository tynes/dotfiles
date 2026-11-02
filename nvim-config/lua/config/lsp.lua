-- Language servers, using Neovim's built-in LSP client.
--
-- Each server's config lives in lsp/<name>.lua. Servers are installed outside
-- Neovim (Homebrew/npm/uv/rustup, see install.sh), not by a plugin, so the
-- same release cooldowns apply. A server whose binary is missing is skipped.
-- Servers only start in trusted projects; see lua/config/trust.lua.

require "config.trust"

local servers = {
  lua_ls = "lua-language-server",
  pyright = "pyright-langserver",
  ruff = "ruff",
  ts_ls = "typescript-language-server",
  solidity_ls = "nomicfoundation-solidity-language-server",
  rust_analyzer = "rust-analyzer",
  nargo = "nargo",
}

local enabled = {}
for name, bin in pairs(servers) do
  if vim.fn.executable(bin) == 1 then table.insert(enabled, name) end
end
vim.lsp.enable(enabled)

vim.diagnostic.config {
  virtual_text = true,
  underline = true,
  severity_sort = true,
  float = { border = "rounded", source = true },
}

-- Formatters to skip on save.
local no_format_on_save = { pyright = true }

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("config.lsp", {}),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    local buf = args.buf

    -- Completion menu as you type ('autocomplete' + omnifunc), with LSP
    -- side effects (auto-imports, snippets) applied on accept.
    if client:supports_method "textDocument/completion" then vim.lsp.completion.enable(true, client.id, buf) end

    if client:supports_method "textDocument/codeLens" then vim.lsp.codelens.enable(true, { bufnr = buf }) end

    if client:supports_method "textDocument/formatting" and not no_format_on_save[client.name] then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup(("config.lsp.format.%d.%d"):format(buf, client.id), {}),
        buffer = buf,
        callback = function()
          if vim.g.format_on_save == false then return end
          vim.lsp.buf.format { bufnr = buf, id = client.id, timeout_ms = 1000 }
        end,
      })
    end
  end,
})

vim.api.nvim_create_user_command("FormatToggle", function()
  vim.g.format_on_save = vim.g.format_on_save == false
  print("Format on save: " .. (vim.g.format_on_save and "on" or "off"))
end, { desc = "Toggle format on save" })
