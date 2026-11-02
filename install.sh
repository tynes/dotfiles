#!/bin/bash
#
# Install the tools these dotfiles expect.
# Supports macOS (Homebrew) and Debian/Ubuntu (apt, x86_64).
#
#   ./install.sh            install everything
#   ./install.sh fzf jj     run only these steps
#   ./install.sh --list     list the steps for this OS
#
# Steps are independent: a failed step is reported at the end and the rest
# still run. Re-running is safe; tools that are already installed are skipped.
#
# Written for bash 3.2 (macOS /bin/bash): no associative arrays, and no
# expanding an empty array under `set -u`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

# --- Packages -----------------------------------------------------------------

BREW_PACKAGES=(
    eza bat zoxide fzf neovim difftastic git-delta direnv tmux git tig htop
    ripgrep fd tree go node pnpm bun python@3 uv gh jj jq just bitwarden-cli
    gcloud-cli awscli claude-code@latest codex nvimpager moor watch tailscale
    ghostty antigravity-cli gnupg orbstack openssh mosh starship worktrunk
    rclone gcalcli wget semgrep hcloud protobuf openjdk@21 maven php fswatch
    superfile muse-code flarectl cloudflare-wrangler coreutils
)

APT_PACKAGES=(
    git tig tmux htop direnv ripgrep fd-find tree curl unzip ca-certificates
    python3 python3-pip python3-venv python-is-python3 build-essential scdoc
    jq procps gnupg openssh-client openssh-server mosh openssl libssl-dev
    pkg-config wget php php-cli php-common bat
)

# --- Steps --------------------------------------------------------------------
# Each step NAME runs the function install_NAME, in this order.

MACOS_STEPS=(
    rust brew_packages python_symlink
    foundry amp grok opencode pi keepassxcr
    nvim_plugins
)

DEBIAN_STEPS=(
    apt_packages rust
    neovim eza fzf zoxide difftastic delta go node pnpm bun uv foundry gh jj
    just bitwarden gcloud awscli claude codex antigravity nvimpager moor
    tailscale ghostty docker starship worktrunk rclone gcalcli semgrep hcloud
    protobuf java maven amp grok opencode pi superfile muse flarectl wrangler
    keepassxcr
    nvim_plugins
)

# Steps that only warn when they fail, so the run can still succeed.
#   ghostty: debian.griffo.io's apt mirror now needs a paid subscription.
OPTIONAL_STEPS=(ghostty)

# --- Output -------------------------------------------------------------------

info()  { printf '\033[0;32m[INFO]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
error() { printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2; }
die()   { error "$@"; exit 1; }

# --- Platform -----------------------------------------------------------------

OS=unknown
DISTRO_ID=""  # debian, ubuntu, ...
CODENAME=""   # bookworm, noble, ...
case "$(uname -s)" in
    Darwin) OS=macos ;;
    Linux)
        if [ -f /etc/debian_version ]; then
            OS=debian
        fi
        if [ -r /etc/os-release ]; then
            # shellcheck source=/dev/null
            DISTRO_ID=$(. /etc/os-release && echo "${ID:-}")
            # shellcheck source=/dev/null
            CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}")
        fi
        ;;
esac

case "$(uname -m)" in
    x86_64) GOARCH=amd64 ;;
    aarch64 | arm64) GOARCH=arm64 ;;
    *) GOARCH=unknown ;;
esac

# Put every directory the installers write to on PATH now, so "already
# installed" checks work in a fresh shell, later steps can find tools that
# earlier steps installed, and vendor scripts that only edit ~/.bashrc when
# their directory is missing from PATH leave it alone (it's a repo symlink).
for dir in "$HOME/.local/bin" "$HOME/.cargo/bin" /usr/local/go/bin \
    "$HOME/.bun/bin" "$HOME/.foundry/bin" "$HOME/.grok/bin" "$HOME/.opencode/bin"; do
    case ":$PATH:" in
        *":$dir:"*) ;;
        *) PATH="$dir:$PATH" ;;
    esac
done
export PATH

TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT

# --- Helpers ------------------------------------------------------------------

have() { command -v "$1" >/dev/null 2>&1; }

# already CMD [LABEL]: true (and says so) if CMD is on PATH.
already() {
    have "$1" || return 1
    info "${2:-$1} already installed"
}

# sudo that also works as root without sudo installed (containers, cloud-init).
sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        if [ "${1:-}" = "-E" ]; then shift; fi
        "$@"
    else
        command sudo "$@"
    fi
}

# A fresh temporary directory, removed when the script exits.
step_tmp() { mktemp -d "$TMP_ROOT/step.XXXXXX"; }

# fetch URL DEST: download over HTTPS, failing on HTTP errors.
fetch() {
    curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --retry-delay 2 -o "$2" "$1"
}

# run_installer URL SHELL [ARGS...]: download a vendor install script, then run
# it. Downloading first means a dropped connection can't run half a script.
# stdin is /dev/null, as it was for `curl | sh`.
run_installer() {
    local url=$1 shell=$2 script
    shift 2
    script="$(step_tmp)/install.sh"
    fetch "$url" "$script"
    "$shell" "$script" "$@" </dev/null
}

# github_api PATH: GET from the GitHub API. Set $GITHUB_TOKEN to avoid the
# anonymous limit of 60 requests an hour.
github_api() {
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        curl -fsSL --retry 3 -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/$1"
    else
        curl -fsSL --retry 3 "https://api.github.com/$1"
    fi
}

# gh_latest_tag OWNER/REPO: tag of the latest release.
gh_latest_tag() {
    local tag
    tag=$(github_api "repos/$1/releases/latest" | jq -r '.tag_name // empty') || true
    if [ -z "$tag" ]; then
        error "Could not find the latest release of $1"
        return 1
    fi
    printf '%s\n' "$tag"
}

# install_release_asset URL BINARY [tar.gz|zip|raw]: download URL, pull BINARY
# out of it and install it to ~/.local/bin. The format is guessed from the URL.
install_release_asset() {
    local url=$1 bin=$2 kind=${3:-} dir found
    if [ -z "$kind" ]; then
        case "${url%%\?*}" in
            *.tar.gz | *.tgz) kind=tar.gz ;;
            *.zip) kind=zip ;;
            *) kind=raw ;;
        esac
    fi
    dir=$(step_tmp)
    fetch "$url" "$dir/download"
    case "$kind" in
        tar.gz) tar -xzf "$dir/download" -C "$dir" ;;
        zip) unzip -q "$dir/download" -d "$dir" ;;
        raw) mv "$dir/download" "$dir/$bin" ;;
    esac
    found=$(find "$dir" -type f -name "$bin" -print -quit)
    if [ -z "$found" ]; then
        error "$bin not found in $url"
        return 1
    fi
    mkdir -p "$BIN_DIR"
    install -m 0755 "$found" "$BIN_DIR/$bin"
    info "$bin installed to $BIN_DIR/$bin"
}

# install_github_bin CMD OWNER/REPO ASSET [BINARY]: install CMD from the latest
# GitHub release. ASSET may use {tag} (v1.2.3) and {version} (1.2.3).
install_github_bin() {
    local cmd=$1 repo=$2 asset=$3 bin=${4:-$1} tag
    already "$cmd" && return
    tag=$(gh_latest_tag "$repo")
    asset=${asset//\{tag\}/$tag}
    asset=${asset//\{version\}/${tag#v}}
    info "Installing $cmd $tag from GitHub releases..."
    install_release_asset "https://github.com/$repo/releases/download/$tag/$asset" "$bin"
}

apt_install() { sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"; }

# add_apt_repo NAME KEY_URL SOURCE: add an apt repository signed by the key at
# KEY_URL. SOURCE is the "deb ..." line; {keyring} becomes the key's path.
add_apt_repo() {
    local name=$1 key_url=$2 source=$3 keyring="/etc/apt/keyrings/$1.gpg" key
    key="$(step_tmp)/key"
    fetch "$key_url" "$key"
    sudo install -m 0755 -d /etc/apt/keyrings
    if grep -q -- '-----BEGIN PGP' "$key"; then
        sudo gpg --dearmor --yes -o "$keyring" "$key"
    else
        sudo install -m 0644 "$key" "$keyring"
    fi
    sudo chmod a+r "$keyring"
    printf '%s\n' "${source//\{keyring\}/$keyring}" |
        sudo tee "/etc/apt/sources.list.d/$name.list" >/dev/null
    sudo apt-get update
}

# apt_repo_install NAME KEY_URL SOURCE PACKAGE...: add an apt repository (see
# add_apt_repo) and install PACKAGEs from it. If that fails the repository is
# removed again, so a broken or paywalled repo can't break later apt runs.
apt_repo_install() {
    local name=$1 key_url=$2 source=$3 rc
    shift 3
    set +e
    (
        set -e
        add_apt_repo "$name" "$key_url" "$source"
        apt_install "$@"
    )
    rc=$?
    set -e
    if [ "$rc" -ne 0 ]; then
        warn "Removing the $name apt repository so it can't break later apt runs"
        sudo rm -f "/etc/apt/sources.list.d/$name.list" "/etc/apt/keyrings/$name.gpg"
    fi
    return "$rc"
}

# uv_tool_install PKG: isolated Python CLI install via uv (or pipx).
uv_tool_install() {
    if have uv; then
        uv tool install "$1"
    elif have pipx; then
        pipx install "$1"
    else
        error "uv or pipx is required to install $1"
        return 1
    fi
}

# npm_global_install ARGS...: `npm install -g`, into ~/.local on Linux. Passes
# --prefix rather than `npm config set prefix`, which would rewrite ~/.npmrc
# (a symlink into this repo).
npm_global_install() {
    if ! have npm; then
        error "Node.js/npm is required but not found"
        return 1
    fi
    if [ "$OS" = debian ]; then
        npm install -g --prefix "$HOME/.local" --no-fund --no-audit "$@"
    else
        npm install -g --no-fund --no-audit "$@"
    fi
}

require_cargo() {
    have cargo && return
    error "cargo is required but not found"
    return 1
}

# --- Package managers ---------------------------------------------------------

find_brew() {
    local p
    for p in "$(command -v brew || true)" /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -n "$p" ] && [ -x "$p" ]; then
            printf '%s\n' "$p"
            return 0
        fi
    done
    return 1
}

# Not a step: every macOS step needs brew on PATH, including in a shell that
# hasn't loaded Homebrew's environment yet (such as right after installing it).
setup_homebrew() {
    local brew_bin script
    if ! brew_bin=$(find_brew); then
        info "Installing Homebrew..."
        script="$(step_tmp)/install.sh"
        fetch https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh "$script"
        /bin/bash "$script" # interactive: it asks for the sudo password
        brew_bin=$(find_brew) || die "Homebrew install finished but brew was not found"
    fi
    eval "$("$brew_bin" shellenv)"
}

install_brew_packages() {
    info "Installing packages via Homebrew..."
    brew install "${BREW_PACKAGES[@]}"
}

install_apt_packages() {
    info "Installing packages via apt..."
    sudo apt-get update
    apt_install "${APT_PACKAGES[@]}"
}

install_rust() {
    already cargo Rust && return
    info "Installing Rust..."
    # ~/.profile already sources ~/.cargo/env, so rustup needn't edit rc files.
    run_installer https://sh.rustup.rs sh -y --no-modify-path
}

# --- macOS --------------------------------------------------------------------

install_python_symlink() {
    if have python; then
        info "'python' command already available"
        return
    fi
    local prefix
    prefix=$(brew --prefix)
    if [ -x "$prefix/bin/python3" ]; then
        ln -sf "$prefix/bin/python3" "$prefix/bin/python"
        info "'python' now points to python3"
    else
        warn "python3 not found in Homebrew prefix, skipping symlink"
    fi
}

# --- Linux: binaries from GitHub releases -------------------------------------

install_eza()        { install_github_bin eza eza-community/eza "eza_x86_64-unknown-linux-musl.tar.gz"; }
install_fzf()        { install_github_bin fzf junegunn/fzf "fzf-{version}-linux_amd64.tar.gz"; }
install_difftastic() { install_github_bin difft Wilfred/difftastic "difft-{tag}-x86_64-unknown-linux-gnu.tar.gz"; }
install_delta()      { install_github_bin delta dandavison/delta "delta-{tag}-x86_64-unknown-linux-gnu.tar.gz"; }
install_jj()         { install_github_bin jj jj-vcs/jj "jj-{tag}-x86_64-unknown-linux-musl.tar.gz"; }
install_just()       { install_github_bin just casey/just "just-{tag}-x86_64-unknown-linux-musl.tar.gz"; }
install_moor()       { install_github_bin moor walles/moor "moor-{tag}-linux-amd64"; }
install_hcloud()     { install_github_bin hcloud hetznercloud/cli "hcloud-linux-amd64.tar.gz"; }

install_bitwarden() {
    already bw bitwarden-cli && return
    # The repo releases every Bitwarden client; take the newest CLI one.
    local tag
    tag=$(github_api "repos/bitwarden/clients/releases?per_page=100" |
        jq -r '[.[].tag_name | select(startswith("cli-v"))][0] // empty')
    [ -n "$tag" ] || die "Could not find the latest bitwarden-cli release"
    info "Installing bitwarden-cli $tag..."
    install_release_asset "https://github.com/bitwarden/clients/releases/download/$tag/bw-linux-${tag#cli-v}.zip" bw
}

install_flarectl() {
    already flarectl && return
    [ "$GOARCH" != unknown ] || die "Unsupported architecture for flarectl: $(uname -m)"
    # flarectl only ships with the v0.x releases of cloudflare-go; "latest" is a
    # newer major version without it, so pick the highest v0 tag.
    local tag
    tag=$(github_api repos/cloudflare/cloudflare-go/git/matching-refs/tags/v0. |
        jq -r '.[].ref | sub("refs/tags/"; "")' | sort -V | tail -n 1)
    [ -n "$tag" ] || die "Could not find the latest flarectl release"
    info "Installing flarectl $tag..."
    install_release_asset "https://github.com/cloudflare/cloudflare-go/releases/download/$tag/flarectl_${tag#v}_linux_$GOARCH.tar.gz" flarectl
}

install_neovim() {
    already nvim neovim && return
    # apt's neovim is usually too old for AstroNvim.
    info "Installing neovim from GitHub releases..."
    local tarball
    tarball="$(step_tmp)/nvim.tar.gz"
    fetch https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz "$tarball"
    sudo rm -rf /opt/nvim-linux-x86_64
    sudo tar -C /opt -xzf "$tarball"
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
}

install_protobuf() {
    already protoc && return
    local tag zip
    tag=$(gh_latest_tag protocolbuffers/protobuf)
    info "Installing protoc $tag..."
    zip="$(step_tmp)/protoc.zip"
    fetch "https://github.com/protocolbuffers/protobuf/releases/download/$tag/protoc-${tag#v}-linux-x86_64.zip" "$zip"
    sudo unzip -q -o "$zip" -d /usr/local bin/protoc 'include/*'
}

install_nvimpager() {
    already nvimpager && return
    info "Installing nvimpager from source..."
    local src
    src="$(step_tmp)/nvimpager"
    git clone --depth 1 https://github.com/lucc/nvimpager.git "$src"
    sudo make -C "$src" install
}

# --- Linux: other downloads ---------------------------------------------------

install_go() {
    already go Go && return
    local version tarball
    version=$(curl -fsSL 'https://go.dev/dl/?mode=json' | jq -r '.[0].version // empty')
    [ -n "$version" ] || die "Could not find the latest Go version"
    info "Installing $version..."
    tarball="$(step_tmp)/go.tar.gz"
    fetch "https://go.dev/dl/$version.linux-amd64.tar.gz" "$tarball"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$tarball"
}

install_awscli() {
    already aws "AWS CLI" && return
    info "Installing AWS CLI..."
    local dir
    dir=$(step_tmp)
    fetch https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip "$dir/awscli.zip"
    unzip -q "$dir/awscli.zip" -d "$dir"
    sudo "$dir/aws/install"
}

install_antigravity() {
    already antigravity "Antigravity CLI" && return
    [ "$GOARCH" != unknown ] || die "Unsupported architecture for Antigravity CLI: $(uname -m)"
    local url
    url=$(curl -fsSL "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_$GOARCH.json" |
        jq -r '.url // empty')
    [ -n "$url" ] || die "Could not find the latest Antigravity CLI download"
    info "Installing Antigravity CLI..."
    install_release_asset "$url" antigravity tar.gz
}

install_muse() {
    already muse "Muse Code" && return
    local arch version
    case "$(uname -m)" in
        x86_64) arch=x86 ;;
        aarch64 | arm64) arch=aarch64 ;;
        *) die "Unsupported architecture for Muse Code: $(uname -m)" ;;
    esac
    version=$(curl -fsSL https://api.meta.ai/muse-code/channels/muse-stable | jq -r '.version // empty')
    [ -n "$version" ] || die "Could not find the latest Muse Code version"
    info "Installing Muse Code $version..."
    install_release_asset "https://lookaside.facebook.com/lookaside/muse/download/?channel=muse&version=$version&file=muse-$arch-linux" muse raw
}

# --- Linux: apt repositories --------------------------------------------------

install_gh() {
    already gh && return
    info "Installing GitHub CLI..."
    apt_repo_install github-cli https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        "deb [arch=$(dpkg --print-architecture) signed-by={keyring}] https://cli.github.com/packages stable main" \
        gh
}

install_gcloud() {
    already gcloud && return
    info "Installing Google Cloud CLI..."
    apt_repo_install google-cloud-sdk https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        "deb [signed-by={keyring}] https://packages.cloud.google.com/apt cloud-sdk main" \
        google-cloud-cli
}

install_ghostty() {
    already ghostty && return
    info "Installing Ghostty from debian.griffo.io..."
    info "(Its apt mirror needs a subscription. Other options: https://ghostty.org/docs/install/binary)"
    # debian.griffo.io only publishes a bookworm suite. This is an optional
    # step (see OPTIONAL_STEPS), so failing here doesn't fail the run.
    apt_repo_install debian.griffo.io https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc \
        "deb [signed-by={keyring}] https://debian.griffo.io/apt bookworm main" \
        ghostty
}

install_java() {
    already java Java && return
    info "Installing Eclipse Temurin 21 JDK..."
    apt_repo_install adoptium https://packages.adoptium.net/artifactory/api/gpg/key/public \
        "deb [signed-by={keyring}] https://packages.adoptium.net/artifactory/deb $CODENAME main" \
        temurin-21-jdk
}

install_maven() {
    already mvn Maven && return
    apt_install maven
}

install_docker() {
    if ! already docker Docker; then
        info "Installing Docker..."
        # Docker publishes separate debian and ubuntu repos; derivatives such as
        # Mint use ubuntu's (CODENAME is already their UBUNTU_CODENAME).
        local distro=ubuntu
        if [ "$DISTRO_ID" = debian ]; then distro=debian; fi
        sudo rm -f /etc/apt/sources.list.d/docker.sources # from older versions of this script
        apt_repo_install docker "https://download.docker.com/linux/$distro/gpg" \
            "deb [arch=$(dpkg --print-architecture) signed-by={keyring}] https://download.docker.com/linux/$distro $CODENAME stable" \
            docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi

    local user=${USER:-$(id -un)}
    if grep -qw docker <<<"$(id -nG "$user")"; then
        info "$user already in docker group"
    elif sudo usermod -aG docker "$user"; then
        info "Added $user to the docker group"
        warn "Log out and back in (or run 'newgrp docker') for it to take effect"
    else
        warn "Could not add $user to the docker group; run: sudo usermod -aG docker $user"
    fi
}

# --- Linux: vendor install scripts --------------------------------------------

install_node() {
    already node Node.js && return
    info "Installing Node.js LTS via NodeSource..."
    local script
    script="$(step_tmp)/setup_lts.sh"
    fetch https://deb.nodesource.com/setup_lts.x "$script"
    sudo -E bash "$script"
    apt_install nodejs
}

install_rclone() {
    already rclone && return
    info "Installing rclone..."
    local script
    script="$(step_tmp)/install.sh"
    fetch https://rclone.org/install.sh "$script"
    sudo bash "$script"
}

install_superfile() {
    already spf superfile && return
    info "Installing superfile..."
    local script
    script="$(step_tmp)/install.sh"
    fetch https://superfile.dev/install.sh "$script"
    bash "$script"
}

install_zoxide()    { already zoxide    || run_installer https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh sh; }
install_pnpm()      { already pnpm      || run_installer https://get.pnpm.io/install.sh sh; }
install_bun()       { already bun       || run_installer https://bun.sh/install bash; }
install_claude()    { already claude "Claude Code" || run_installer https://claude.ai/install.sh bash; }
install_codex()     { already codex     || run_installer https://chatgpt.com/codex/install.sh sh; }
install_tailscale() { already tailscale || run_installer https://tailscale.com/install.sh sh; }
install_starship()  { already starship  || run_installer https://starship.rs/install.sh sh -y; }

install_uv() {
    already uv && return
    # ~/.local/bin is already on PATH via ~/.profile.
    UV_NO_MODIFY_PATH=1 run_installer https://astral.sh/uv/install.sh sh
}

# --- Both platforms -----------------------------------------------------------

install_foundry() {
    already forge Foundry && return
    info "Installing Foundry..."
    run_installer https://foundry.paradigm.xyz bash
    "$HOME/.foundry/bin/foundryup"
}

install_amp()  { already amp  || run_installer https://ampcode.com/install.sh bash; }
install_grok() { already grok "Grok CLI" || run_installer https://x.ai/cli/install.sh bash; }

install_opencode() {
    already opencode && return
    # PATH for ~/.opencode/bin is handled in .bash/init.sh.
    run_installer https://opencode.ai/install bash --no-modify-path
}

install_pi() {
    already pi && return
    info "Installing pi..."
    # The official pi.dev script prompts on /dev/tty, so it can't run unattended.
    # Install the npm package with the same flags the script uses.
    npm_global_install --ignore-scripts --min-release-age=0 @earendil-works/pi-coding-agent
}

install_wrangler() {
    already wrangler && return
    info "Installing wrangler..."
    npm_global_install --allow-scripts=esbuild,workerd wrangler
}

install_worktrunk() {
    already wt worktrunk && return
    require_cargo
    cargo install worktrunk
}

install_gcalcli() { already gcalcli || uv_tool_install gcalcli; }
install_semgrep() { already semgrep || uv_tool_install semgrep; }

# keepassxcr (used by envrc-vault / `vault_export` in .envrc): always install the
# latest crates.io release. cargo skips the build when that version is already
# installed and upgrades an older one.
install_keepassxcr() {
    if ! have cargo; then
        warn "cargo not found, skipping keepassxcr"
        return
    fi
    local installed
    installed=$(cargo install --list)
    info "Installing the latest keepassxcr release..."
    # A git or local-checkout install blocks a crates.io one unless --force.
    if grep -q '^keepassxcr .* (' <<<"$installed"; then
        cargo install --locked --force keepassxcr
    else
        cargo install --locked keepassxcr
    fi
}

# Pre-install Neovim plugins once setup.sh has linked the config.
install_nvim_plugins() {
    if [ ! -L "$HOME/.config/nvim" ]; then
        info "Neovim config not linked yet; plugins will install on first launch"
        return
    fi
    if ! have nvim; then
        warn "Neovim not found, skipping plugin installation"
        return
    fi
    info "Installing Neovim plugins..."
    # The first start bootstraps lazy.nvim; the second syncs every plugin.
    nvim --headless +qa 2>/dev/null || true
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Neovim plugin sync reported errors"
}

# --- Main ---------------------------------------------------------------------

FAILED=()

# run_step NAME: run install_NAME in a subshell with errexit on, and record a
# failure instead of stopping. (`install_NAME || ...` would turn errexit off
# inside the function, so a failing command partway through would go unnoticed.)
run_step() {
    local rc
    set +e
    (
        set -e
        "install_$1"
    )
    rc=$?
    set -e
    if [ "$rc" -eq 0 ]; then return; fi
    case " ${OPTIONAL_STEPS[*]} " in
        *" $1 "*)
            warn "Optional step '$1' failed (exit $rc); continuing"
            return
            ;;
    esac
    error "Step '$1' failed (exit $rc)"
    # Everything after this needs curl, jq and a compiler.
    if [ "$1" = apt_packages ]; then die "Base packages failed to install; stopping"; fi
    FAILED+=("$1")
}

usage() {
    sed -n '3,11s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"
}

main() {
    local steps step
    case "$OS" in
        macos) steps=("${MACOS_STEPS[@]}") ;;
        debian) steps=("${DEBIAN_STEPS[@]}") ;;
        *) die "Unsupported OS. Please install packages manually." ;;
    esac

    case "${1:-}" in
        -h | --help) usage; return ;;
        --list) printf '%s\n' "${steps[@]}"; return ;;
    esac

    if [ $# -eq 0 ]; then
        set -- "${steps[@]}"
    else
        for step in "$@"; do
            case " ${steps[*]} " in
                *" $step "*) ;;
                *) die "Unknown step '$step' for $OS (see ./install.sh --list)" ;;
            esac
        done
    fi

    info "Installing for $OS${DISTRO_ID:+ ($DISTRO_ID $CODENAME)}"
    if [ "$OS" = macos ]; then setup_homebrew; fi

    for step in "$@"; do
        run_step "$step"
    done

    if [ "${#FAILED[@]}" -gt 0 ]; then
        error "${#FAILED[@]} step(s) failed: ${FAILED[*]}"
        error "Re-run them with: $SCRIPT_DIR/install.sh ${FAILED[*]}"
        exit 1
    fi
    info "Done! Now run ./setup.sh to create symlinks."
}

# Run only when executed, so tests can source this file.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
