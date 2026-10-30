local trust = require "config.trust"

---@type vim.lsp.Config
return {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_dir = trust.root {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "pyrightconfig.json",
    ".git",
  },
  -- Use the project's .venv when there is one (only reached in trusted projects).
  before_init = function(_, config)
    local venv = vim.fn.finddir(".venv", (config.root_dir or vim.fn.getcwd()) .. ";")
    if venv ~= "" then config.settings.python.pythonPath = vim.fn.fnamemodify(venv, ":p") .. "bin/python" end
  end,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
      },
    },
  },
}
