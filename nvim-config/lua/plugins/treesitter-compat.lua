-- Neovim 0.12 compatibility shim for nvim-treesitter's archived `master` branch.
--
-- master's custom query directives/predicates (set-lang-from-info-string!,
-- set-lang-from-mimetype!, downcase!, nth?, is?, kind-eq?) read `match[id]` as a
-- single TSNode. They relied on the old `all = false` registration behavior,
-- which Neovim 0.12 removed -- handlers now always receive an array of nodes.
-- That turns `node` into a table, so `node:range()` is nil and parsing crashes:
--   .../vim/treesitter.lua:197: attempt to call method 'range' (a nil value)
--
-- Fix: wrap query.add_directive/add_predicate to normalize the match table back
-- to a single (last) node per capture, then force nvim-treesitter to re-register
-- its handlers through the wrappers. No reimplementation, so it can't drift from
-- upstream, and it survives plugin updates. Remove once on the `main` branch.
return {
  "nvim-treesitter/nvim-treesitter",
  optional = true, -- extend the existing spec; don't redefine config/opts
  init = function(plugin)
    -- AstroNvim adds nvim-treesitter to the rtp and loads query_predicates early
    -- (see its treesitter spec's init). Run that first so the handlers exist,
    -- then re-register them through our normalizing wrappers.
    require("lazy.core.loader").add_to_rtp(plugin)
    pcall(require, "nvim-treesitter.query_predicates")

    local q = require "vim.treesitter.query"
    local orig_directive, orig_predicate = q.add_directive, q.add_predicate

    -- Collapse `match[id]` (a TSNode[] on 0.12) back to the single last node the
    -- master-branch handlers expect, matching the old `all = false` semantics.
    local function last_node(match)
      local single = {}
      for id, value in pairs(match) do
        single[id] = type(value) == "table" and value[#value] or value
      end
      return single
    end

    q.add_directive = function(name, handler, opts)
      return orig_directive(name, function(match, ...) return handler(last_node(match), ...) end, opts)
    end
    q.add_predicate = function(name, handler, opts)
      return orig_predicate(name, function(match, ...) return handler(last_node(match), ...) end, opts)
    end

    -- Force a fresh load so every nvim-treesitter handler registers via the
    -- wrappers above (its opts use force = true, so this overwrites cleanly).
    package.loaded["nvim-treesitter.query_predicates"] = nil
    pcall(require, "nvim-treesitter.query_predicates")

    -- Restore the originals so other plugins' (array-aware) handlers are untouched.
    q.add_directive, q.add_predicate = orig_directive, orig_predicate
  end,
}
