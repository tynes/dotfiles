local opt = vim.opt

opt.number = true
opt.relativenumber = false
opt.signcolumn = "auto"
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.cursorline = true
opt.laststatus = 3
opt.title = true
opt.termguicolors = true
opt.mouse = "a"
opt.fillchars = { eob = " " }

opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 0
opt.shiftround = true
opt.copyindent = true
opt.preserveindent = true

opt.ignorecase = true
opt.smartcase = true
opt.infercase = true

opt.splitbelow = true
opt.splitright = true
opt.confirm = true
opt.undofile = true
opt.writebackup = false
opt.updatetime = 300
opt.timeoutlen = 500
opt.virtualedit = "block"
opt.diffopt:append { "algorithm:histogram", "linematch:60" }
opt.spell = false

-- Completion menu as you type: LSP (omnifunc) first, then buffer words.
opt.autocomplete = true
opt.complete = { "o", ".^5", "w^5", "b^5" }
opt.completeopt = { "menuone", "noselect", "popup", "fuzzy" }
opt.pumheight = 10

-- Archive plugins. tar.vim and zip.vim have had command-injection bugs from
-- crafted archives, and nothing here needs to browse archives.
vim.g.loaded_gzip = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_2html_plugin = 1

-- Clipboard. Locally Neovim uses pbcopy/pbpaste. Over ssh, copy with OSC 52
-- but paste what was last copied in this Neovim, so `p` never asks the
-- terminal to read the clipboard (Ghostty prompts for that). Paste from the
-- system clipboard with the terminal's paste key instead.
opt.clipboard = "unnamedplus"
if vim.env.SSH_TTY then
  local osc52 = require "vim.ui.clipboard.osc52"
  local last = {}
  local function copy(reg)
    local send = osc52.copy(reg)
    return function(lines, regtype)
      last[reg] = { lines, regtype }
      send(lines, regtype)
    end
  end
  local function paste(reg)
    return function() return last[reg] or { { "" }, "v" } end
  end
  vim.g.clipboard = {
    name = "OSC 52 (copy only)",
    copy = { ["+"] = copy "+", ["*"] = copy "*" },
    paste = { ["+"] = paste "+", ["*"] = paste "*" },
  }
end

vim.filetype.add { extension = { nr = "noir" } }
