-- Treesitter: highlighting from Neovim, parsers from nvim-treesitter (main).
--
-- Parsers are an explicit list. Nothing is installed just because a file of
-- a new type was opened: each parser is C code compiled and loaded into
-- Neovim, downloaded at the revision pinned in nvim-treesitter's parsers.lua.
-- Installing needs the tree-sitter CLI and a C compiler.

local M = {}

M.parsers = {
  "bash",
  "c",
  "diff",
  "dockerfile",
  "gitcommit",
  "go",
  "html",
  "javascript",
  "json",
  "just",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "rust",
  "solidity",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
}

local function can_build() return vim.fn.executable "tree-sitter" == 1 and vim.fn.executable "cc" == 1 end

--- Install any missing parsers from the list. No-op for installed ones.
--- `wait` blocks until done (for install.sh).
function M.install(wait)
  if not can_build() then
    if wait then vim.api.nvim_echo({ { "tree-sitter CLI or C compiler missing; skipping parsers\n" } }, true, {}) end
    return
  end
  local task = require("nvim-treesitter").install(M.parsers)
  if wait then task:wait(300000) end
end

-- Skip treesitter for big files, like AstroNvim's large_buf did.
local max_bytes, max_lines = 256 * 1024, 10000

local function too_big(buf)
  local ok, stat = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
  return (ok and stat and stat.size > max_bytes) or vim.api.nvim_buf_line_count(buf) > max_lines
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("config.treesitter", {}),
  callback = function(args)
    if too_big(args.buf) then return end
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Parsers must match the plugin version, so rebuild them after it updates.
vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("config.treesitter.update", {}),
  callback = function(ev)
    if ev.data.spec.name == "nvim-treesitter" and ev.data.kind == "update" then
      if not ev.data.active then vim.cmd.packadd "nvim-treesitter" end
      vim.cmd "TSUpdate"
    end
  end,
})

return M
