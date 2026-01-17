#!/bin/bash
#
# Install dependencies for dotfiles
# Supports: macOS (Homebrew), Debian/Ubuntu (apt)
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect OS and package manager
detect_os() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
info "Detected OS: $OS"

# Install Homebrew on macOS if not present
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

# Core packages available in most package managers
install_packages() {
    case $OS in
        macos)
            install_homebrew
            info "Installing packages via Homebrew..."
            brew install \
                eza \
                bat \
                zoxide \
                fzf \
                neovim \
                difftastic \
                git-delta \
                direnv \
                tmux \
                git \
                ripgrep \
                fd \
                go \
                node \
                python@3 \
                uv \
                gh \
                jj \
                nvimpager \
                moor

            # Foundry - Ethereum development toolkit
            install_foundry
            ;;
        debian)
            info "Updating apt cache..."
            sudo apt update

            info "Installing packages via apt..."
            sudo apt install -y \
                git \
                tmux \
                fzf \
                direnv \
                ripgrep \
                fd-find \
                curl \
                unzip \
                python3 \
                python3-pip \
                python3-venv \
                build-essential \
                scdoc

            # neovim - get latest from GitHub releases (apt version is often outdated)
            install_neovim_linux

            # eza - not in default repos, install from GitHub
            install_eza_linux

            # bat - package name differs
            sudo apt install -y bat || sudo apt install -y batcat

            # zoxide - install from GitHub
            install_zoxide_linux

            # difftastic - install from cargo or GitHub
            install_difftastic_linux

            # git-delta - install from GitHub
            install_delta_linux

            # Go - install from official releases
            install_go_linux

            # Node.js - install from NodeSource
            install_node_linux

            # uv - Python package manager
            install_uv_linux

            # Foundry - Ethereum development toolkit
            install_foundry

            # gh - GitHub CLI
            install_gh_linux

            # jj - Jujutsu version control
            install_jj_linux

            # nvimpager - neovim-based pager
            install_nvimpager

            # moor - pager
            install_moor
            ;;
        *)
            error "Unsupported OS. Please install packages manually."
            exit 1
            ;;
    esac
}

install_neovim_linux() {
    if command -v nvim &> /dev/null; then
        info "neovim already installed"
        return
    fi
    info "Installing neovim from GitHub releases..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm nvim-linux-x86_64.tar.gz
}

install_eza_linux() {
    if command -v eza &> /dev/null; then
        info "eza already installed"
        return
    fi
    info "Installing eza..."
    # Try apt first (available in newer Ubuntu/Debian)
    if sudo apt install -y eza 2>/dev/null; then
        return
    fi
    # Fall back to cargo
    if command -v cargo &> /dev/null; then
        cargo install eza
    else
        warn "Could not install eza. Install Rust/cargo first, then run: cargo install eza"
    fi
}

install_zoxide_linux() {
    if command -v zoxide &> /dev/null; then
        info "zoxide already installed"
        return
    fi
    info "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

install_difftastic_linux() {
    if command -v difft &> /dev/null; then
        info "difftastic already installed"
        return
    fi
    info "Installing difftastic from GitHub releases..."
    mkdir -p ~/.local/bin
    curl -LO https://github.com/Wilfred/difftastic/releases/latest/download/difft-x86_64-unknown-linux-gnu.tar.gz
    tar xzf difft-x86_64-unknown-linux-gnu.tar.gz
    mv difft ~/.local/bin/
    rm difft-x86_64-unknown-linux-gnu.tar.gz
}

install_delta_linux() {
    if command -v delta &> /dev/null; then
        info "git-delta already installed"
        return
    fi
    info "Installing git-delta from GitHub releases..."

    # Get the latest version tag from GitHub API
    DELTA_VERSION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep '"tag_name"' | cut -d'"' -f4)

    if [ -z "$DELTA_VERSION" ]; then
        error "Failed to get latest delta version"
        return 1
    fi

    info "Downloading git-delta $DELTA_VERSION..."
    mkdir -p ~/.local/bin
    curl -LO "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
    tar xzf "delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
    mv "delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu/delta" ~/.local/bin/
    rm -rf "delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu" "delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
}

install_go_linux() {
    if command -v go &> /dev/null; then
        info "Go already installed"
        return
    fi
    info "Installing Go from official releases..."

    # Get the latest Go version from the official API
    GO_VERSION=$(curl -s 'https://go.dev/dl/?mode=json' | grep -o '"version":"go[0-9.]*"' | head -1 | cut -d'"' -f4 | sed 's/go//')

    if [ -z "$GO_VERSION" ]; then
        error "Failed to get latest Go version"
        return 1
    fi

    info "Downloading Go $GO_VERSION..."
    curl -LO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
    # Note: PATH should include /usr/local/go/bin (add to .bashrc if needed)
}

install_node_linux() {
    if command -v node &> /dev/null; then
        info "Node.js already installed"
        return
    fi
    info "Installing Node.js via NodeSource..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
}

install_uv_linux() {
    if command -v uv &> /dev/null; then
        info "uv already installed"
        return
    fi
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_foundry() {
    if command -v forge &> /dev/null; then
        info "Foundry already installed"
        return
    fi
    info "Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    ~/.foundry/bin/foundryup
}

install_gh_linux() {
    if command -v gh &> /dev/null; then
        info "gh already installed"
        return
    fi
    info "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
}

install_jj_linux() {
    if command -v jj &> /dev/null; then
        info "jj already installed"
        return
    fi
    info "Installing Jujutsu from GitHub releases..."

    # Get the latest version tag from GitHub API
    JJ_VERSION=$(curl -s https://api.github.com/repos/jj-vcs/jj/releases/latest | grep '"tag_name"' | cut -d'"' -f4)

    if [ -z "$JJ_VERSION" ]; then
        error "Failed to get latest jj version"
        return 1
    fi

    info "Downloading jj $JJ_VERSION..."
    mkdir -p ~/.local/bin

    # Download and extract the binary
    curl -L "https://github.com/jj-vcs/jj/releases/download/${JJ_VERSION}/jj-${JJ_VERSION}-x86_64-unknown-linux-musl.tar.gz" -o /tmp/jj.tar.gz
    tar -xzf /tmp/jj.tar.gz -C /tmp
    mv /tmp/jj ~/.local/bin/
    chmod +x ~/.local/bin/jj
    rm /tmp/jj.tar.gz

    info "jj installed to ~/.local/bin/jj"
}

install_nvimpager() {
    if command -v nvimpager &> /dev/null; then
        info "nvimpager already installed"
        return
    fi
    info "Installing nvimpager..."
    git clone https://github.com/lucc/nvimpager.git /tmp/nvimpager
    cd /tmp/nvimpager
    sudo make install
    cd -
    rm -rf /tmp/nvimpager
}

install_moor() {
    if command -v moor &> /dev/null; then
        info "moor already installed"
        return
    fi
    info "Installing moor..."
    install_rust
    cargo install moor
}

# Install Rust/Cargo if needed for some tools
install_rust() {
    if ! command -v cargo &> /dev/null; then
        info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
}

# Main
main() {
    info "Starting dependency installation..."

    install_packages

    info "Done! Now run ./setup.sh to create symlinks."
}

main "$@"
