-- Plugins, managed by Neovim's built-in vim.pack.
--
-- Revisions are pinned in nvim-pack-lock.json (committed). A fresh machine
-- installs exactly those revisions. To update:
--   :lua vim.pack.update()   review the changes, then :write to apply or :quit
-- and commit the new lockfile. Revert with `git checkout nvim-pack-lock.json`
-- and `:lua vim.pack.update(nil, { target = "lockfile" })`.

local gh = function(repo) return "https://github.com/" .. repo end

vim.pack.add({
  gh "rebelot/kanagawa.nvim",
  { src = gh "nvim-treesitter/nvim-treesitter", version = "main" },
  gh "lewis6991/gitsigns.nvim",
  gh "ibhagwan/fzf-lua",
}, {
  -- Ask before installing anything new; skip the prompt in headless runs
  -- (install.sh), where the lockfile decides.
  confirm = #vim.api.nvim_list_uis() > 0,
})

require("kanagawa").setup {}
vim.cmd.colorscheme "kanagawa"

require("config.treesitter").install()

require("gitsigns").setup {
  on_attach = function(buf)
    local gs = require "gitsigns"
    local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc }) end
    map("]g", function() gs.nav_hunk "next" end, "Next git hunk")
    map("[g", function() gs.nav_hunk "prev" end, "Previous git hunk")
    map("<Leader>gp", gs.preview_hunk, "Preview git hunk")
    map("<Leader>gl", gs.blame_line, "Git blame line")
    map("<Leader>gs", gs.stage_hunk, "Stage git hunk")
    map("<Leader>gr", gs.reset_hunk, "Reset git hunk")
    map("<Leader>gd", gs.diffthis, "Git diff this file")
  end,
}

local fzf = require "fzf-lua"
fzf.setup {}
local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { desc = desc }) end
map("<Leader>ff", fzf.files, "Find files")
map("<Leader>fw", fzf.live_grep, "Find words")
map("<Leader>fc", fzf.grep_cword, "Find word under cursor")
map("<Leader>fb", fzf.buffers, "Find buffers")
map("<Leader>fo", fzf.oldfiles, "Find old files")
map("<Leader>fh", fzf.helptags, "Find help")
map("<Leader>fk", fzf.keymaps, "Find keymaps")
map("<Leader>f'", fzf.marks, "Find marks")
map("<Leader>fr", fzf.registers, "Find registers")
map("<Leader>fg", fzf.git_files, "Find git files")
map("<Leader>f<CR>", fzf.resume, "Resume last search")
map("<Leader>gt", fzf.git_status, "Git status")
map("<Leader>lD", fzf.diagnostics_workspace, "Search diagnostics")
map("<Leader>lS", fzf.lsp_document_symbols, "Document symbols")
