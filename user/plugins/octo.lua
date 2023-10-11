return {
  "pwntester/octo.nvim",
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  cmd = "Octo",
  config = function(_, opts)
    require("octo").setup(opts)
    -- vim.treesitter.language.register("markdown", "octo")
    vim.api.nvim_create_autocmd("FileType", {
      desc = "Set Up Octo Which-Key",
      group = vim.api.nvim_create_augroup("octo_settings", { clear = true }),
      pattern = "octo",
      callback = function(event)
        vim.api.nvim_buf_set_keymap(0, "i", "@", "@<C-x><C-o>", { silent = true, noremap = true })
        vim.api.nvim_buf_set_keymap(0, "i", "#", "#<C-x><C-o>", { silent = true, noremap = true })
        require("which-key").register({
          i = { name = " Issue" },
          p = { name = " PR" },
          a = { name = " Assignee" },
          l = { name = " Label" },
          r = { name = " React" },
          c = { name = " Comment" },
          v = { name = " Reviewer" },
        }, { prefix = "<leader>", buffer = event.buf })
      end,
    })
  end,
}
