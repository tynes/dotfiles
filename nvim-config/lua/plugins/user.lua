-- You can also add or configure plugins by creating files in this `plugins/` folder
-- Here are custom user plugins:

---@type LazySpec
return {
  -- Kanagawa colorscheme
  {
    "rebelot/kanagawa.nvim",
    opts = {},
  },
  -- Unpin aerial.nvim to get v3.1.0+ fix for treesitter on Neovim 0.12+
  {
    "stevearc/aerial.nvim",
    version = false,
  },
}
