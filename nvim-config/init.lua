-- Neovim config. Needs Neovim 0.12+ (vim.pack, built-in LSP config/completion).
-- See README.md for the layout and how plugins and language servers are managed.

vim.g.mapleader = " "
vim.g.maplocalleader = ","

require "config.options"
require "config.keymaps"
require "config.plugins"
require "config.lsp"
