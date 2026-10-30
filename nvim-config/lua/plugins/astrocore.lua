-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

local function osc52_copy_only()
  if not vim.env.SSH_TTY then return nil end
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
  return {
    name = "OSC 52 (copy only)",
    copy = { ["+"] = copy "+", ["*"] = copy "*" },
    paste = { ["+"] = paste "+", ["*"] = paste "*" },
  }
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- passed to `vim.filetype.add`
    filetypes = {
      -- see `:h vim.filetype.add` for usage
      extension = {
        foo = "fooscript",
      },
      filename = {
        [".foorc"] = "fooscript",
      },
      pattern = {
        [".*/etc/foo/.*"] = "fooscript",
      },
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = false, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "auto", -- sets vim.opt.signcolumn to auto
        wrap = true, -- sets vim.opt.wrap
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file

        -- Over ssh, copy with OSC 52 but paste what was last copied in this
        -- Neovim, so `p` never asks the terminal to read the clipboard (Ghostty
        -- prompts for that). Paste from the system clipboard with the terminal's
        -- paste key instead. Locally, Neovim picks pbcopy/pbpaste by itself.
        clipboard = osc52_copy_only(),
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- first key is the mode
      n = {
        -- second key is the lefthand side of the map

        -- LSP mappings
        gd = { function() vim.lsp.buf.definition() end, desc = "Go to definition" },
        gD = { function() vim.lsp.buf.declaration() end, desc = "Go to declaration" },
        gr = { function() vim.lsp.buf.references() end, desc = "Go to references" },
        gi = { function() vim.lsp.buf.implementation() end, desc = "Go to implementation" },
        K = { function() vim.lsp.buf.hover() end, desc = "Hover documentation" },
        ["<Leader>rn"] = { function() vim.lsp.buf.rename() end, desc = "Rename symbol" },
        ["<Leader>ca"] = { function() vim.lsp.buf.code_action() end, desc = "Code action" },

        -- navigate buffer tabs
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- mappings seen under group name "Buffer"
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },

        -- tables with just a `desc` key will be registered with which-key if it's installed
        -- this is useful for naming menus
        -- ["<Leader>b"] = { desc = "Buffers" },

        -- setting a mapping to false will disable it
        -- ["<C-S>"] = false,
      },
    },
  },
}
