# Neovim config

A small config for Neovim 0.12+. It replaces AstroNvim (48 plugins plus Mason)
with Neovim's built-in features and four pinned plugins.

## Layout

```
init.lua                 leader keys, loads lua/config/*
lua/config/options.lua   options, clipboard, filetypes
lua/config/keymaps.lua   keymaps
lua/config/plugins.lua   vim.pack plugins and their setup
lua/config/treesitter.lua  parser list, highlighting
lua/config/lsp.lua       enables servers, completion, format on save
lua/config/trust.lua     :Trust / :Untrust
lsp/<server>.lua         one file per language server
syntax/noir.vim          Noir syntax (copied from noir-nvim)
nvim-pack-lock.json      pinned plugin revisions (commit this)
```

## Plugins

| Plugin | Why |
|---|---|
| kanagawa.nvim | colorscheme |
| nvim-treesitter (`main`) | builds parsers; highlighting itself is built in |
| gitsigns.nvim | git signs, hunk navigation, blame |
| fzf-lua | file, grep, buffer, symbol pickers (uses the `fzf` binary) |

Plugins are managed by `vim.pack`. A fresh machine installs the exact revisions
in `nvim-pack-lock.json`, and asks before installing anything new.

To update: `:lua vim.pack.update()` (or `<Leader>pu`). It fetches and shows
each plugin's changes; `:write` applies, `:quit` cancels. Then commit the
lockfile. To roll back: `git checkout nvim-pack-lock.json`, restart, and run
`:lua vim.pack.update(nil, { target = "lockfile" })`.

## Language servers

Configured in `lsp/` and enabled with `vim.lsp.enable()`. They're installed by
`install.sh` (Homebrew, npm, uv, rustup), not by a plugin, so the 7-day
release cooldowns in `.npmrc` and `uv.toml` apply. Servers whose binary isn't
on `PATH` are skipped.

lua_ls, pyright, ruff, ts_ls, solidity_ls, rust_analyzer, nargo (Noir).

### Trusted projects

Language servers run code from the project they open (rust-analyzer runs
`build.rs` and proc macros, pyright runs the project's Python, ts_ls loads the
project's TypeScript). So they only start in projects you trust:

- `:Trust` trusts the current git repo (or pass a directory)
- `:Untrust` removes it and stops its servers
- `:TrustList` shows the list (stored in `~/.local/state/nvim/trusted-projects`)

Untrusted projects still get treesitter highlighting.

## Treesitter

Parsers are an explicit list in `lua/config/treesitter.lua`; nothing installs
automatically when you open a new file type. Add a language there and restart.
Building parsers needs the `tree-sitter` CLI and a C compiler.

## Keys

`<Space>` is leader. Most of the old AstroNvim maps are kept:

| Keys | Action |
|---|---|
| `<Leader>ff` / `fw` / `fc` / `fb` / `fo` | find files / grep / word under cursor / buffers / recent |
| `<Leader>fh` / `fk` / `f'` / `fr` / `fg` | help / keymaps / marks / registers / git files |
| `<Leader>gt` | git status |
| `]g` `[g`, `<Leader>gp` / `gl` / `gs` / `gr` / `gd` | hunks, preview / blame / stage / reset / diff |
| `gd` `gD` `gr` `gi` `K`, `<Leader>rn`, `<Leader>ca` | LSP |
| `<Leader>ld` / `lD` / `lS` | line diagnostics / all diagnostics / symbols |
| `<Leader>w` / `q` / `Q` / `c` / `n` / `e` | save / quit / quit all / close buffer / new / explorer |
| `<Leader>/` | comment |
| `<Leader>u` | undotree |
| `<C-h/j/k/l>` | move between windows |
| `<Tab>` `<S-Tab>` `<CR>` | completion menu |

Built in to Neovim: `grn` `gra` `grr` `gri` `gO`, `[d` `]d`, `[b` `]b`, `gcc`.
`:FormatToggle` turns format-on-save off and on.
