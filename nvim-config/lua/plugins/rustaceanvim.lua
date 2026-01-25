---@type LazySpec
return {
  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    ft = { "rust" },
    init = function()
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                buildScripts = {
                  enable = true,
                },
              },
              procMacro = {
                enable = true,
              },
              check = {
                command = "clippy",
              },
            },
          },
        },
      }
    end,
  },
}
