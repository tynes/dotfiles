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
  -- Use the project's .venv when there is one. Search upward from the root,
  -- but not past the trusted directory: a .venv above it was never trusted,
  -- and pyright runs its python.
  before_init = function(_, config)
    local top = config.root_dir and trust.trusted_dir(config.root_dir)
    if not top then return end
    local venv = vim.fs.find(".venv", {
      path = config.root_dir,
      upward = true,
      type = "directory",
      stop = vim.fs.dirname(top),
    })[1]
    if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
      config.settings.python.pythonPath = venv .. "/bin/python"
    end
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
