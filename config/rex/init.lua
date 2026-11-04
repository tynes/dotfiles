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

-- These match tmux's built-in defaults rather than lines in .tmux.conf.

-- New tab. tmux: prefix + c (new-window)
rex.bind(p("c"), "client.tab.new")

-- Close the focused pane. tmux: prefix + x (kill-pane)
-- Unlike tmux, Rex closes it right away without asking first.
rex.bind(p("x"), "pane.close")

-- Go to tab 1-9. tmux: prefix + 1-9 (select-window)
-- Tabs count from 1 here, matching base-index 1 in .tmux.conf.
for i = 1, 9 do
  rex.bind(p(tostring(i)), "client.tab.goto", { index = i })
end

-- Session picker. tmux: prefix + w (choose-tree)
-- Rex has no tab picker, so this lists sessions, not tabs.
rex.bind(p("w"), "session.switch")

-- Reload config. tmux: bind r source-file ~/.tmux.conf
rex.bind(p("r"), "client.config.reload")

-- Claude sessions sidebar: a list of past and running Claude Code sessions
-- on the left, like the desktop app. Press again to close it.
-- See bin/claude-sessions.
--
-- Written with Rex's Lua calls rather than the rex CLI: an app connected to
-- this server from another Mac runs the action there, where `rex` would
-- reach that Mac's own server. These calls go to the server the app shows.
local sidebar_label = "claude-sessions"
local sidebar_columns = 40
local terminal = "com.superlogical.terminal"

local function find_sidebar(session_id, block_id)
  local view, err = rex.session.view{ session_id = session_id }
  if view == nil then error(err, 0) end
  for _, win in ipairs(view.windows or {}) do
    local here, found = false, nil
    for _, layer in ipairs(win.layers or {}) do
      for _, b in ipairs(layer.blocks or {}) do
        if b.block_id == block_id then here = true end
        if b.label == sidebar_label then found = b.block_id end
      end
    end
    if here then return found end
  end
  return nil
end

rex.action{
  name = "claude_sidebar",
  title = "Toggle Claude Sessions",
  description = "Show or hide the Claude Code sessions sidebar beside this pane.",
  keywords = "claude sessions history sidebar resume",
  run = function(ctx)
    local session_id, block_id = ctx.session_id, ctx.block_id
    if not session_id or not block_id then
      error("no focused pane", 0)
    end

    local existing = find_sidebar(session_id, block_id)
    if existing then
      local _, err = rex.call("block.close", { session_id = session_id, block_id = existing })
      if err then error(err, 0) end
      return
    end

    -- About 40 columns, never more than a third of the pane being split.
    local ratio = 0.22
    local size = rex.block.call(terminal, "size", { session_id = session_id, block_id = block_id })
    if size and size.columns and size.columns > 0 then
      ratio = math.max(0.05, math.min(0.33, sidebar_columns / size.columns))
    end
    local pwd = rex.block.call(terminal, "pwd", { session_id = session_id, block_id = block_id }) or {}

    -- $HOME is expanded by the shell on the server's machine.
    local command = { "sh", "-c", 'exec "$HOME/bin/claude-sessions" "$@"', "claude-sessions",
      "--main-block", block_id }
    if ctx.client_id then
      table.insert(command, "--client")
      table.insert(command, ctx.client_id)
    end
    local options = { command = command }
    if pwd.path and pwd.path ~= "" then options.cwd = pwd.path end

    local created, err = rex.session.new_split{
      session_id = session_id,
      anchor_id = block_id,
      direction = "horizontal",
      side = "before",
      ratio = ratio,
      focus = false,
      layout = { block = { flavor = terminal .. ".shell", label = sidebar_label, options = options } },
    }
    if created == nil then error(err, 0) end

    -- Rex evens out a new split right after creating it (Beta 0.1.0), so
    -- set the border again a moment later.
    local new_block = created.block_ids and created.block_ids[1]
    if new_block then
      local function resize()
        rex.session.resize_pane{
          session_id = session_id, direction = "horizontal",
          before_block_id = new_block, after_block_id = block_id, ratio = ratio,
        }
      end
      -- Config actions have no timers; waiting on a command doesn't hold Rex up.
      resize()
      rex.exec({ "/bin/sleep", "0.3" }, { timeout = 5 })
      resize()
    end
  end,
}
rex.bind(p("e"), "claude_sidebar")
