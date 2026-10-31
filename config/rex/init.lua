-- Rex config: mirrors the pane bindings in ~/.tmux.conf.
-- Docs: https://www.superlogical.com/rex/docs/customize/keyboard-shortcuts
-- Apply changes with `rex config reload`, or prefix + r below.
--
-- The prefix is ctrl+b, the same as tmux (.tmux.conf never changes it).
-- Notes on how this differs from tmux:
--   * Resize amounts in Rex are a percent of the split, not cells.
--   * pane.split has no cwd option; the new pane's directory is up to Rex.
--   * Shortcuts set in the Rex app (Change Shortcut...) override this file.

local prefix = "ctrl+b"

local function p(key)
  return prefix .. ">" .. key
end

-- ctrl+b starts a sequence, so press it twice to send ctrl+b to the
-- terminal (for example to a tmux running over ssh).
rex.bind(p("ctrl+b"), "pane.send_key", { key = "ctrl+b" })

-- Splits. tmux: bind v split-window -h / bind s split-window -v
rex.bind(p("v"), "pane.split", { direction = "right" })
rex.bind(p("s"), "pane.split", { direction = "down" })

-- Vim-style pane focus with the prefix. tmux: bind h/j/k/l select-pane
rex.bind(p("h"), "pane.focus", { direction = "left" })
rex.bind(p("j"), "pane.focus", { direction = "down" })
rex.bind(p("k"), "pane.focus", { direction = "up" })
rex.bind(p("l"), "pane.focus", { direction = "right" })

-- Pane focus without the prefix. tmux: bind -n M-h/j/k/l select-pane
rex.bind("alt+h", "pane.focus", { direction = "left" })
rex.bind("alt+j", "pane.focus", { direction = "down" })
rex.bind("alt+k", "pane.focus", { direction = "up" })
rex.bind("alt+l", "pane.focus", { direction = "right" })

-- Same with arrows. tmux: bind -n M-Left/Right/Up/Down select-pane
rex.bind("alt+left", "pane.focus", { direction = "left" })
rex.bind("alt+down", "pane.focus", { direction = "down" })
rex.bind("alt+up", "pane.focus", { direction = "up" })
rex.bind("alt+right", "pane.focus", { direction = "right" })

-- Big resize steps. tmux: bind H/J/K/L resize-pane -L/-D/-U/-R 5
-- Rex's default step is 5% of the split.
rex.bind(p("shift+h"), "pane.resize", { direction = "left" })
rex.bind(p("shift+j"), "pane.resize", { direction = "down" })
rex.bind(p("shift+k"), "pane.resize", { direction = "up" })
rex.bind(p("shift+l"), "pane.resize", { direction = "right" })

-- Small resize steps. tmux: bind M-h/j/k/l resize-pane (1 cell)
rex.bind(p("alt+h"), "pane.resize", { direction = "left", amount = 1 })
rex.bind(p("alt+j"), "pane.resize", { direction = "down", amount = 1 })
rex.bind(p("alt+k"), "pane.resize", { direction = "up", amount = 1 })
rex.bind(p("alt+l"), "pane.resize", { direction = "right", amount = 1 })

-- Previous/next tab (tmux windows). tmux: bind -n S-Left/S-Right
rex.bind("shift+left", "client.tab.previous")
rex.bind("shift+right", "client.tab.next")

-- Reload config. tmux: bind r source-file ~/.tmux.conf
rex.bind(p("r"), "client.config.reload")
