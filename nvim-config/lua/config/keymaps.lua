-- Keymaps. Plugin maps live next to their setup in lua/config/plugins.lua.
-- Neovim also has built-in maps worth knowing (see :h default-mappings):
--   grn rename, gra code action, grr references, gri implementation, gO symbols,
--   K hover, [d ]d diagnostics, [b ]b buffers, [q ]q quickfix, gcc comment.

local map = vim.keymap.set

-- Files, buffers, windows
map("n", "<Leader>w", "<Cmd>write<CR>", { desc = "Save" })
map("n", "<Leader>q", "<Cmd>confirm quit<CR>", { desc = "Quit window" })
map("n", "<Leader>Q", "<Cmd>confirm qall<CR>", { desc = "Quit Neovim" })
map("n", "<Leader>n", "<Cmd>enew<CR>", { desc = "New file" })
map("n", "<Leader>e", "<Cmd>Explore<CR>", { desc = "File explorer" })
map("n", "<Leader>c", function()
  local buf = vim.api.nvim_get_current_buf()
  vim.cmd.bprevious()
  if vim.api.nvim_get_current_buf() == buf then vim.cmd.enew() end
  pcall(vim.cmd, "confirm bdelete " .. buf)
end, { desc = "Close buffer" })
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Comments
map("n", "<Leader>/", "gcc", { remap = true, desc = "Toggle comment" })
map("x", "<Leader>/", "gc", { remap = true, desc = "Toggle comment" })

-- LSP
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "gr", vim.lsp.buf.references, { desc = "Go to references" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
map("n", "<Leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<Leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<Leader>ld", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- Completion menu: Tab/S-Tab to move, Enter to accept a selected item.
map("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then return "<C-n>" end
  if vim.snippet.active { direction = 1 } then return "<Cmd>lua vim.snippet.jump(1)<CR>" end
  return "<Tab>"
end, { expr = true, desc = "Next completion / snippet field" })
map("i", "<S-Tab>", function()
  if vim.fn.pumvisible() == 1 then return "<C-p>" end
  if vim.snippet.active { direction = -1 } then return "<Cmd>lua vim.snippet.jump(-1)<CR>" end
  return "<S-Tab>"
end, { expr = true, desc = "Previous completion / snippet field" })
map("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1 then return "<C-y>" end
  return "<CR>"
end, { expr = true, desc = "Accept completion" })

-- Undotree (built in)
vim.cmd.packadd "nvim.undotree"
map("n", "<Leader>u", function() require("undotree").open() end, { desc = "Undo tree" })

-- Plugins
map("n", "<Leader>pu", function() vim.pack.update() end, { desc = "Review plugin updates" })
map("n", "<Leader>ps", function() vim.pack.update(nil, { offline = true }) end, { desc = "Plugin status" })
