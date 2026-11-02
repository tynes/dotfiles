#!/bin/bash
#
# Symlink the dotfiles in this repo into $HOME.
#
#   ./setup.sh              create or update the links
#   ./setup.sh --dry-run    show what would change, change nothing
#
# Safe to re-run. Links that are already right are left alone. Anything else
# in the way is moved to a private backup directory, never deleted. This
# script makes no network calls and never needs sudo; ./install.sh installs
# the tools.
#
# Written for bash 3.2 (macOS /bin/bash): no associative arrays, and no
# expanding an empty array under `set -u`.

set -euo pipefail

# Absolute path to this repo, from the script's location rather than $PWD, so
# the links are right wherever this is run from.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backups"

DRY_RUN=0
BACKUP_DIR=""   # created on first use
BACKED_UP=0
FAILED=0
LINKED_SRCS=""  # newline-separated repo paths, for the checks at the end
LINKED_DESTS=""
DIR_LINKS=()

# --- Output -------------------------------------------------------------------

# Messages show $HOME as ~. (Via a variable: bash 3.2 keeps the quotes in
# ${x//a/"~"}.)
TILDE='~'
short() { local s="$*"; printf '%s' "${s//"$HOME"/$TILDE}"; }

info()  { printf '\033[0;32m[INFO]\033[0m %s\n' "$(short "$*")"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$(short "$*")"; }
error() { printf '\033[0;31m[ERROR]\033[0m %s\n' "$(short "$*")" >&2; }
die()   { error "$@"; exit 1; }

# run CMD...: run CMD, or only print it under --dry-run.
run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  would run: %s\n' "$(short "$*")"
    else
        "$@"
    fi
}

# in_list ITEM LIST: true if ITEM is a line of the newline-separated LIST.
in_list() {
    case "
$2
" in
        *"
$1
"*) return 0 ;;
    esac
    return 1
}

# --- Safety checks ------------------------------------------------------------

# Every link points into this repo, so whoever can write to the repo can change
# what your shell runs at login. Make sure that is only you.
check_environment() {
    # Catches `sudo ./setup.sh` keeping your $HOME, which would leave
    # root-owned files behind in it.
    [ -O "$HOME" ] || die "\$HOME ($HOME) is not owned by $(id -un). Run setup.sh as the user who owns it, without sudo."

    git -C "$DOTFILES" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
        die "$DOTFILES is not a git checkout. Clone the repo with git so setup.sh can check what it links."

    local foreign
    foreign=$(find "$DOTFILES" ! -user "$(id -u)" -print 2>/dev/null | head -n 5) || true
    if [ -n "$foreign" ]; then
        error "These files in the repo are owned by someone else:"
        printf '  %s\n' "$foreign" >&2
        die "Fix the ownership (e.g. sudo chown -R $(id -un) \"$DOTFILES\") and re-run."
    fi

    # Group- or world-writable files would let another account edit your shell
    # config. Removing that permission only tightens access to your own files.
    local writable
    writable=$(find "$DOTFILES" ! -type l \( -perm -020 -o -perm -002 \) -print | wc -l | tr -d ' ')
    if [ "$writable" -gt 0 ]; then
        warn "$writable path(s) in the repo are group- or world-writable; removing that permission"
        if [ "$DRY_RUN" -eq 1 ]; then
            printf '  would run: find %s ! -type l ( -perm -020 -o -perm -002 ) -exec chmod go-w {} +\n' "$DOTFILES"
        else
            find "$DOTFILES" ! -type l \( -perm -020 -o -perm -002 \) -exec chmod go-w {} +
        fi
    fi
}

# --- Linking ------------------------------------------------------------------

# backup PATH: move PATH into this run's backup directory, keeping its path
# relative to $HOME so nothing collides.
backup() {
    local path=$1 rel
    rel=${path#"$HOME"/}
    if [ -z "$BACKUP_DIR" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            BACKUP_DIR="$BACKUP_ROOT/<timestamp>"
        else
            mkdir -p "$BACKUP_ROOT"
            chmod 700 "$BACKUP_ROOT"
            # mktemp makes the directory mode 700 with an unpredictable name.
            BACKUP_DIR=$(mktemp -d "$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S).XXXXXX")
        fi
    fi
    info "Backing up $path"
    run mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    run mv "$path" "$BACKUP_DIR/$rel"
    BACKED_UP=$((BACKED_UP + 1))
}

# link REL DEST: make DEST a symlink to REL (a path in this repo).
link() {
    local rel=$1 dest=$2 src="$DOTFILES/$1" current parent existing
    LINKED_SRCS="$LINKED_SRCS
$rel"
    LINKED_DESTS="$LINKED_DESTS
$dest"

    if [ ! -e "$src" ]; then
        error "$rel does not exist in the repo"
        FAILED=1
        return
    fi
    # Only link what git tracks, so a stray untracked file in the repo can
    # never end up in $HOME.
    if ! git -C "$DOTFILES" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
        error "$rel is not tracked by git; not linking it"
        FAILED=1
        return
    fi
    if [ -d "$src" ]; then DIR_LINKS+=("$rel"); fi

    # Never touch anything inside the repo, as would happen if a parent
    # directory (say ~/.config) were itself a link into it: the backup would
    # move repo files out and the link would land in the repo. Checked before
    # anything changes, on the nearest directory that already exists.
    parent=$(dirname "$dest")
    existing=$parent
    while [ ! -d "$existing" ]; do existing=$(dirname "$existing"); done
    case "$(cd "$existing" && pwd -P)/" in
        "$(cd "$DOTFILES" && pwd -P)"/*)
            error "$parent resolves into the repo; not linking $dest"
            FAILED=1
            return
            ;;
    esac

    if [ -L "$dest" ]; then
        current=$(readlink "$dest")
        if [ "$current" = "$src" ]; then
            return  # already right
        fi
        case "$current" in
            "$DOTFILES"/*)
                # An older link into this repo: nothing to keep.
                info "Replacing $dest (was -> $current)"
                run rm -f "$dest"
                ;;
            *) backup "$dest" ;;
        esac
    elif [ -e "$dest" ]; then
        backup "$dest"
    fi

    if [ ! -d "$parent" ]; then
        run mkdir -p "$parent"
    fi
    info "Linking $dest -> $src"
    run ln -s "$src" "$dest"
}

# has_mode PATH MODE: true if PATH's permission bits are exactly MODE.
has_mode() { [ -n "$(find "$1" -maxdepth 0 -perm "$2" 2>/dev/null)" ]; }

# set_mode PATH MODE: chmod PATH to MODE unless it already is.
set_mode() {
    if [ -e "$1" ] && ! has_mode "$1" "$2"; then
        info "Setting $1 to mode $2"
        run chmod "$2" "$1"
    fi
}

# ensure_private_dir DIR: DIR exists, mode 700.
ensure_private_dir() {
    if [ ! -d "$1" ]; then
        run mkdir -p "$1"
    fi
    set_mode "$1" 700
}

# --- What gets linked ---------------------------------------------------------
# Directories are linked whole when the tool never writes into them. jj, uv and
# git are linked per file: git-signing-refresh writes ~/.config/jj/conf.d/, which
# must not land in the repo.

link_all() {
    local f
    for f in .bash .bash_profile .bashrc .bunfig.toml .gitconfig .inputrc \
        .npmrc .profile .screenrc .tigrc .tmux.conf; do
        link "$f" "$HOME/$f"
    done

    link bin                  "$HOME/bin"
    link nvim-config          "$HOME/.config/nvim"
    link config/ghostty       "$HOME/.config/ghostty"
    link config/starship.toml "$HOME/.config/starship.toml"
    link config/jj/config.toml "$HOME/.config/jj/config.toml"
    link config/wt.toml       "$HOME/.config/wt.toml"
    link config/uv/uv.toml    "$HOME/.config/uv/uv.toml"
    link config/direnv        "$HOME/.config/direnv"
    link config/rex           "$HOME/.config/rex"
    link config/git/ignore    "$HOME/.config/git/ignore"

    # SSH refuses a config that others can write, and ~/.ssh holds keys.
    ensure_private_dir "$HOME/.ssh"
    # Per-machine hosts go here, outside git; the tracked config Includes them.
    ensure_private_dir "$HOME/.ssh/config.d"
    set_mode "$DOTFILES/config/ssh/config" 600
    link config/ssh/config "$HOME/.ssh/config"

    local vscode=""
    case "$OS" in
        Darwin)
            link aerospace.toml "$HOME/.aerospace.toml"
            vscode="$HOME/Library/Application Support/Code/User"
            ;;
        Linux)
            vscode="$HOME/.config/Code/User"
            ;;
    esac
    if [ -n "$vscode" ] && [ -d "$vscode" ]; then
        link settings.json "$vscode/settings.json"
    else
        # Still counts as handled for the "not linked" check below.
        LINKED_SRCS="$LINKED_SRCS
settings.json"
        info "VS Code not found; skipping settings.json"
    fi
}

# --- Checks after linking -----------------------------------------------------

# Files in a linked directory that git doesn't track are live in $HOME too
# (a script in bin/ is on PATH). Point them out.
report_untracked() {
    [ "${#DIR_LINKS[@]}" -gt 0 ] || return 0
    local untracked
    untracked=$(git -C "$DOTFILES" ls-files --others -x .DS_Store -- "${DIR_LINKS[@]}")
    if [ -n "$untracked" ]; then
        warn "Untracked files inside linked directories (these are live in \$HOME):"
        printf '%s\n' "$untracked" | sed 's/^/  /'
    fi
}

# A tracked top-level dotfile that link_all doesn't mention was probably added
# without updating this script.
report_unlinked() {
    local f
    for f in $(git -C "$DOTFILES" ls-files | sed -n 's#^\(\.[^/]*\).*#\1#p' | sort -u); do
        case "$f" in .gitignore) continue ;; esac
        in_list "$f" "$LINKED_SRCS" || warn "$f is tracked but setup.sh doesn't link it"
    done
}

# Links into this repo that setup.sh no longer manages: dangling links to
# deleted files, or old backups that are just links back into the repo.
report_stale() {
    local l stale=""
    while IFS= read -r l; do
        case "$(readlink "$l")" in
            "$DOTFILES"/*) in_list "$l" "$LINKED_DESTS" || stale="$stale$l -> $(readlink "$l")
" ;;
        esac
    done <<EOF
$(find "$HOME" -maxdepth 1 -type l 2>/dev/null
  find "$HOME/.config" -maxdepth 2 -type l 2>/dev/null
  find "$HOME/.ssh" -maxdepth 1 -type l 2>/dev/null)
EOF
    if [ -n "$stale" ]; then
        warn "Links into the repo that setup.sh doesn't manage (safe to remove with rm, no -r):"
        short "$stale" | sed 's/^/  /'
    fi
}

# --- Main ---------------------------------------------------------------------

usage() {
    sed -n '3,11s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"
}

main() {
    case "${1:-}" in
        "") ;;
        -n | --dry-run) DRY_RUN=1 ;;
        -h | --help) usage; return ;;
        *) usage >&2; exit 2 ;;
    esac

    [ "$DRY_RUN" -eq 0 ] || info "Dry run: nothing will be changed"
    info "Linking dotfiles from $DOTFILES"
    check_environment
    link_all

    # Turns commit signing on or off depending on whether this machine has the
    # key. Called by repo path, since ~/bin may not be on PATH yet.
    # Skipped after a failure, since it writes into ~/.config/jj.
    if [ "$FAILED" -ne 0 ]; then
        warn "Skipping git-signing-refresh because some links failed"
    elif [ "$DRY_RUN" -eq 0 ]; then
        "$DOTFILES/bin/git-signing-refresh"
    else
        printf '  would run: %s\n' "$DOTFILES/bin/git-signing-refresh"
    fi

    report_untracked
    report_unlinked
    report_stale

    if [ "$BACKED_UP" -gt 0 ]; then
        info "Moved $BACKED_UP existing item(s) to $BACKUP_DIR"
        info "To restore one, move it back over the link (mv -f)."
    fi
    if [ "$FAILED" -ne 0 ]; then
        error "Some links were not created; see the errors above"
        exit 1
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
        info "Dry run complete"
    else
        info "Done. Open a new login shell to pick up the changes."
        info "Run 'nvim' once to install plugins, then :Trust in projects where language servers may run."
    fi
}

main "$@"
