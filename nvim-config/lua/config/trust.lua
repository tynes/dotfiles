-- Trusted projects.
--
-- Most language servers run code from the project they open: rust-analyzer
-- runs build.rs and proc macros, pyright runs the project's Python,
-- typescript-language-server loads the project's own TypeScript, lua_ls can
-- load workspace plugins, and so on. So servers only start in directories
-- listed here. Everything else still gets syntax highlighting, just no LSP.
--
--   :Trust [dir]    trust a directory (default: the current git repo)
--   :Untrust [dir]  stop trusting it and stop its servers
--   :TrustList      show trusted directories
--
-- The list is one path per line in stdpath("state")/trusted-projects.

local M = {}

local file = vim.fn.stdpath "state" .. "/trusted-projects"

local function real(path) return vim.uv.fs_realpath(path) or vim.fs.normalize(path) end

local function read()
  if vim.fn.filereadable(file) == 0 then return {} end
  return vim.tbl_filter(function(line) return line ~= "" end, vim.fn.readfile(file))
end

local function write(list)
  vim.fn.mkdir(vim.fs.dirname(file), "p")
  vim.fn.writefile(list, file)
end

--- Whether `dir` is a trusted directory or inside one.
function M.is_trusted(dir)
  dir = real(dir)
  for _, trusted in ipairs(read()) do
    if dir == trusted or vim.fs.relpath(trusted, dir) then return true end
  end
  return false
end

-- Untrusted roots each buffer asked for, so :Trust knows what to trust and we
-- only warn once per root.
local pending = {}
local warned = {}

--- Gate a root on trust. Used by every config in lsp/.
--- Calls `on_dir(root)` only when `root` is trusted.
function M.gate(bufnr, root, on_dir)
  if not root then return end
  if M.is_trusted(root) then return on_dir(root) end
  pending[bufnr] = root
  if not warned[root] then
    warned[root] = true
    vim.notify(("LSP is off in untrusted project:\n  %s\nRun :Trust to turn it on."):format(root), vim.log.levels.WARN)
  end
end

--- root_dir function for configs whose root is found by marker files.
function M.root(markers)
  return function(bufnr, on_dir) M.gate(bufnr, vim.fs.root(bufnr, markers), on_dir) end
end

local function default_dir(bufnr) return vim.fs.root(bufnr, ".git") or pending[bufnr] or vim.fn.getcwd() end

-- Re-run LSP auto-start for buffers under `dir` (only the vim.lsp.enable
-- autocommands, not ftplugins).
local function restart_lsp_under(dir)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.api.nvim_buf_is_loaded(buf) and name ~= "" and vim.fs.relpath(dir, real(name)) then
      pending[buf] = nil
      pcall(vim.api.nvim_exec_autocmds, "FileType", { group = "nvim.lsp.enable", buffer = buf })
    end
  end
end

function M.trust(dir)
  dir = real(dir)
  if vim.fn.isdirectory(dir) == 0 then return vim.notify("Not a directory: " .. dir, vim.log.levels.ERROR) end
  local list = read()
  if not vim.tbl_contains(list, dir) then
    table.insert(list, dir)
    write(list)
  end
  warned = {}
  vim.notify("Trusted " .. dir)
  restart_lsp_under(dir)
end

function M.untrust(dir)
  dir = real(dir)
  write(vim.tbl_filter(function(d) return d ~= dir end, read()))
  for _, client in ipairs(vim.lsp.get_clients()) do
    if client.root_dir and not M.is_trusted(client.root_dir) then client:stop() end
  end
  vim.notify("Untrusted " .. dir)
end

vim.api.nvim_create_user_command(
  "Trust",
  function(opts) M.trust(opts.args ~= "" and vim.fn.expand(opts.args) or default_dir(0)) end,
  { nargs = "?", complete = "dir", desc = "Trust a project so language servers can start in it" }
)

vim.api.nvim_create_user_command(
  "Untrust",
  function(opts) M.untrust(opts.args ~= "" and vim.fn.expand(opts.args) or default_dir(0)) end,
  { nargs = "?", complete = "dir", desc = "Stop trusting a project and stop its language servers" }
)

vim.api.nvim_create_user_command("TrustList", function()
  local list = read()
  print(#list == 0 and "No trusted projects" or table.concat(list, "\n"))
end, { desc = "List trusted projects" })

return M
