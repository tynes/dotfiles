local trust = require "config.trust"

---@type vim.lsp.Config
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_dir = trust.root {
    ".luarc.json",
    ".luarc.jsonc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    ".git",
  },
  settings = { Lua = {} },
  -- In a Neovim config (init.lua + lua/), teach lua_ls about the `vim` API.
  on_init = function(client)
    local root = client.root_dir or ""
    if not (vim.uv.fs_stat(root .. "/init.lua") and vim.uv.fs_stat(root .. "/lua")) then return end
    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
      runtime = { version = "LuaJIT", path = { "lua/?.lua", "lua/?/init.lua" } },
      workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
    })
  end,
}
