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
                tig \
                htop \
                ripgrep \
                fd \
                tree \
                go \
                node \
                pnpm \
                python@3 \
                uv \
                gh \
                jj \
                jq \
                just \
                bitwarden-cli \
                gcloud-cli \
                awscli \
                claude-code \
                codex \
                gemini-cli \
                nvimpager \
                moor \
                watch \
                tailscale \
                ghostty \
                gnupg \
                orbstack \
                openssh \
                starship \
                worktrunk \
                rclone \
                gcalcli \
                wget \
                hcloud

            # Foundry - Ethereum development toolkit
            install_foundry
            ;;
        debian)
            info "Updating apt cache..."
            sudo apt update

            info "Installing packages via apt..."
            sudo apt install -y \
                git \
                tig \
                tmux \
                htop \
                direnv \
                ripgrep \
                fd-find \
                tree \
                curl \
                unzip \
                python3 \
                python3-pip \
                python3-venv \
                build-essential \
                scdoc \
                jq \
                procps \
                gnupg \
                openssh-client \
                openssh-server \
                openssl \
                libssl-dev \
                pkg-config \
                wget

            # neovim - get latest from GitHub releases (apt version is often outdated)
            install_neovim_linux

            # eza - not in default repos, install from GitHub
            install_eza_linux

            # bat - package name differs
            sudo apt install -y bat || sudo apt install -y batcat

            # fzf - install from GitHub (apt version is outdated)
            install_fzf_linux

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

            # pnpm - fast, disk space efficient package manager
            install_pnpm_linux

            # uv - Python package manager
            install_uv_linux

            # Foundry - Ethereum development toolkit
            install_foundry

            # gh - GitHub CLI
            install_gh_linux

            # jj - Jujutsu version control
            install_jj_linux

            # just - command runner
            install_just_linux

            # bitwarden-cli - password manager CLI
            install_bitwarden_cli_linux

            # gcloud - Google Cloud CLI
            install_gcloud_linux

            # awscli - AWS CLI
            install_awscli_linux

            # claude-code - Claude Code CLI
            install_claude_code_linux

            # codex - OpenAI Codex CLI
            install_codex_linux

            # gemini-cli - Gemini CLI
            install_gemini_cli_linux

            # nvimpager - neovim-based pager
            install_nvimpager

            # moor - pager
            install_moor

            # tailscale - VPN and mesh networking
            install_tailscale_linux

            # ghostty - terminal emulator
            install_ghostty_linux

            # docker - container platform
            install_docker_linux

            # starship - cross-shell prompt
            install_starship_linux

            # worktrunk - workspace management
            install_worktrunk_linux

            # rclone - cloud storage sync
            install_rclone_linux

            # gcalcli - Google Calendar CLI
            install_gcalcli_linux

            # hcloud - Hetzner Cloud CLI
            install_hcloud_linux
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
    info "Installing eza from GitHub releases..."

    # Get the latest version tag from GitHub API
    EZA_VERSION=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep '"tag_name"' | cut -d'"' -f4)

    if [ -z "$EZA_VERSION" ]; then
        error "Failed to get latest eza version"
        return 1
    fi

    info "Downloading eza $EZA_VERSION..."
    mkdir -p ~/.local/bin
    curl -L "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz" -o /tmp/eza.tar.gz
    tar -xzf /tmp/eza.tar.gz -C ~/.local/bin
    chmod +x ~/.local/bin/eza
    rm /tmp/eza.tar.gz

    info "eza installed to ~/.local/bin/eza"
}

install_zoxide_linux() {
    if command -v zoxide &> /dev/null; then
        info "zoxide already installed"
        return
    fi
    info "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

install_fzf_linux() {
    if command -v fzf &> /dev/null; then
        info "fzf already installed"
        return
    fi
    info "Installing fzf from GitHub releases..."

    # Get the latest version tag from GitHub API
    FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | jq -r '.tag_name')

    if [ -z "$FZF_VERSION" ] || [ "$FZF_VERSION" = "null" ]; then
        error "Failed to get latest fzf version"
        return 1
    fi

    # Version in filename doesn't have 'v' prefix
    FZF_VERSION_NUM=${FZF_VERSION#v}

    info "Downloading fzf $FZF_VERSION..."
    mkdir -p ~/.local/bin
    curl -fL "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION_NUM}-linux_amd64.tar.gz" -o /tmp/fzf.tar.gz
    tar -xzf /tmp/fzf.tar.gz -C ~/.local/bin
    chmod +x ~/.local/bin/fzf
    rm /tmp/fzf.tar.gz

    info "fzf installed to ~/.local/bin/fzf"
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
    GO_VERSION=$(curl -s 'https://go.dev/dl/?mode=json' | grep -m1 '"version"' | cut -d'"' -f4 | sed 's/go//')

    if [ -z "$GO_VERSION" ]; then
        error "Failed to get latest Go version"
        return 1
    fi

    info "Downloading Go $GO_VERSION..."
    curl -LO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
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

install_pnpm_linux() {
    if command -v pnpm &> /dev/null; then
        info "pnpm already installed"
        return
    fi
    info "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    info "pnpm installed"
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

    # Download and extract the binary (extract only the jj binary, not the directory metadata)
    curl -L "https://github.com/jj-vcs/jj/releases/download/${JJ_VERSION}/jj-${JJ_VERSION}-x86_64-unknown-linux-musl.tar.gz" -o /tmp/jj.tar.gz
    tar -xzf /tmp/jj.tar.gz -C ~/.local/bin ./jj
    chmod +x ~/.local/bin/jj
    rm /tmp/jj.tar.gz

    info "jj installed to ~/.local/bin/jj"
}

install_just_linux() {
    if command -v just &> /dev/null; then
        info "just already installed"
        return
    fi
    info "Installing just from GitHub releases..."

    # Get the latest version tag from GitHub API
    JUST_VERSION=$(curl -s https://api.github.com/repos/casey/just/releases/latest | grep '"tag_name"' | cut -d'"' -f4)

    if [ -z "$JUST_VERSION" ]; then
        error "Failed to get latest just version"
        return 1
    fi

    info "Downloading just $JUST_VERSION..."
    mkdir -p ~/.local/bin
    curl -L "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz" -o /tmp/just.tar.gz
    tar -xzf /tmp/just.tar.gz -C ~/.local/bin just
    chmod +x ~/.local/bin/just
    rm /tmp/just.tar.gz

    info "just installed to ~/.local/bin/just"
}

install_bitwarden_cli_linux() {
    if command -v bw &> /dev/null; then
        info "bitwarden-cli already installed"
        return
    fi
    info "Installing bitwarden-cli from GitHub releases..."

    # Get the latest CLI version tag from GitHub API
    BW_VERSION=$(curl -s https://api.github.com/repos/bitwarden/clients/releases | grep '"tag_name"' | grep 'cli-v' | head -1 | cut -d'"' -f4)

    if [ -z "$BW_VERSION" ]; then
        error "Failed to get latest bitwarden-cli version"
        return 1
    fi

    info "Downloading bitwarden-cli $BW_VERSION..."
    mkdir -p ~/.local/bin
    curl -L "https://github.com/bitwarden/clients/releases/download/${BW_VERSION}/bw-linux-${BW_VERSION#cli-v}.zip" -o /tmp/bw.zip
    unzip -o /tmp/bw.zip -d ~/.local/bin
    chmod +x ~/.local/bin/bw
    rm /tmp/bw.zip

    info "bitwarden-cli installed to ~/.local/bin/bw"
}

install_gcloud_linux() {
    if command -v gcloud &> /dev/null; then
        info "gcloud already installed"
        return
    fi
    info "Installing Google Cloud CLI..."

    # Add the Cloud SDK distribution URI as a package source
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

    # Import the Google Cloud public key
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

    # Update and install the Cloud SDK
    sudo apt update && sudo apt install -y google-cloud-cli

    info "Google Cloud CLI installed"
}

install_awscli_linux() {
    if command -v aws &> /dev/null; then
        info "AWS CLI already installed"
        return
    fi
    info "Installing AWS CLI..."

    # Download and install AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -o /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install
    rm -rf /tmp/awscliv2.zip /tmp/aws

    info "AWS CLI installed"
}

install_claude_code_linux() {
    if command -v claude &> /dev/null; then
        info "Claude Code already installed"
        return
    fi
    info "Installing Claude Code..."

    # Check if Node.js is available
    if ! command -v npm &> /dev/null; then
        error "Node.js/npm is required to install Claude Code but not found"
        return 1
    fi

    # Configure npm to use ~/.local for global installs (binaries go to ~/.local/bin)
    mkdir -p ~/.local
    npm config set prefix ~/.local

    # Install Claude Code via npm
    npm install -g @anthropic-ai/claude-code

    info "Claude Code installed to ~/.local/bin"
}

install_codex_linux() {
    if command -v codex &> /dev/null; then
        info "codex already installed"
        return
    fi
    info "Installing OpenAI Codex from GitHub releases..."

    # Get the latest version tag from GitHub API using jq for reliable parsing
    CODEX_VERSION=$(curl -s https://api.github.com/repos/openai/codex/releases/latest | jq -r '.tag_name')

    if [ -z "$CODEX_VERSION" ] || [ "$CODEX_VERSION" = "null" ]; then
        error "Failed to get latest codex version"
        return 1
    fi

    info "Downloading codex $CODEX_VERSION..."
    mkdir -p ~/.local/bin
    curl -fL "https://github.com/openai/codex/releases/download/${CODEX_VERSION}/codex-x86_64-unknown-linux-musl.tar.gz" -o /tmp/codex.tar.gz
    tar -xzf /tmp/codex.tar.gz -C /tmp
    mv /tmp/codex-x86_64-unknown-linux-musl ~/.local/bin/codex
    chmod +x ~/.local/bin/codex
    rm /tmp/codex.tar.gz

    info "codex installed to ~/.local/bin/codex"
}

install_gemini_cli_linux() {
    if command -v gemini &> /dev/null; then
        info "Gemini CLI already installed"
        return
    fi
    info "Installing Gemini CLI..."

    # Check if Node.js is available
    if ! command -v npm &> /dev/null; then
        error "Node.js/npm is required to install Gemini CLI but not found"
        return 1
    fi

    # Configure npm to use ~/.local for global installs (binaries go to ~/.local/bin)
    mkdir -p ~/.local
    npm config set prefix ~/.local

    # Install Gemini CLI via npm
    npm install -g @google/gemini-cli

    info "Gemini CLI installed to ~/.local/bin"
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
    info "Installing moor from GitHub releases..."

    # Get the latest version tag from GitHub API
    MOOR_VERSION=$(curl -s https://api.github.com/repos/walles/moor/releases/latest | grep '"tag_name"' | cut -d'"' -f4)

    if [ -z "$MOOR_VERSION" ]; then
        error "Failed to get latest moor version"
        return 1
    fi

    info "Downloading moor $MOOR_VERSION..."
    mkdir -p ~/.local/bin
    curl -L "https://github.com/walles/moor/releases/download/${MOOR_VERSION}/moor-${MOOR_VERSION}-linux-amd64" -o ~/.local/bin/moor
    chmod +x ~/.local/bin/moor

    info "moor installed to ~/.local/bin/moor"
}

install_tailscale_linux() {
    if command -v tailscale &> /dev/null; then
        info "tailscale already installed"
        return
    fi
    info "Installing Tailscale..."

    # Use Tailscale's official install script
    curl -fsSL https://tailscale.com/install.sh | sh

    info "Tailscale installed"
}

install_ghostty_linux() {
    if command -v ghostty &> /dev/null; then
        info "ghostty already installed"
        return
    fi
    info "Installing Ghostty from debian.griffo.io..."

    # Add the repository GPG key
    curl -sS https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/debian.griffo.io.gpg

    # Add the repository (use bookworm which is available on debian.griffo.io)
    echo "deb https://debian.griffo.io/apt bookworm main" | sudo tee /etc/apt/sources.list.d/debian.griffo.io.list > /dev/null

    # Update and install
    sudo apt update
    sudo apt install -y ghostty

    info "Ghostty installed"
}

install_docker_linux() {
    if command -v docker &> /dev/null; then
        info "Docker already installed"
        return
    fi
    info "Installing Docker from official repository..."

    # Set up Docker's apt repository
    sudo apt update
    sudo apt install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to apt sources
    sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    # Install Docker packages
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    info "Docker installed"
}

install_starship_linux() {
    if command -v starship &> /dev/null; then
        info "starship already installed"
        return
    fi
    info "Installing starship from official installer..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    info "starship installed"
}

install_worktrunk_linux() {
    if command -v wt &> /dev/null; then
        info "worktrunk already installed"
        return
    fi
    info "Installing worktrunk via cargo..."

    if ! command -v cargo &> /dev/null; then
        error "Cargo is required to install worktrunk but not found"
        return 1
    fi

    cargo install worktrunk

    info "worktrunk installed"
}

install_rclone_linux() {
    if command -v rclone &> /dev/null; then
        info "rclone already installed"
        return
    fi
    info "Installing rclone..."

    # Use rclone's official install script
    curl https://rclone.org/install.sh | sudo bash

    info "rclone installed"
}

install_gcalcli_linux() {
    if command -v gcalcli &> /dev/null; then
        info "gcalcli already installed"
        return
    fi
    info "Installing gcalcli..."

    # Use uv tool install (similar to pipx) for isolated installation
    if command -v uv &> /dev/null; then
        uv tool install gcalcli
    else
        pip3 install --user gcalcli
    fi

    info "gcalcli installed"
}

install_hcloud_linux() {
    if command -v hcloud &> /dev/null; then
        info "hcloud already installed"
        return
    fi
    info "Installing Hetzner Cloud CLI from GitHub releases..."

    # Get the latest version tag from GitHub API
    HCLOUD_VERSION=$(curl -s https://api.github.com/repos/hetznercloud/cli/releases/latest | jq -r '.tag_name')

    if [ -z "$HCLOUD_VERSION" ] || [ "$HCLOUD_VERSION" = "null" ]; then
        error "Failed to get latest hcloud version"
        return 1
    fi

    info "Downloading hcloud $HCLOUD_VERSION..."
    mkdir -p ~/.local/bin
    curl -fL "https://github.com/hetznercloud/cli/releases/download/${HCLOUD_VERSION}/hcloud-linux-amd64.tar.gz" -o /tmp/hcloud.tar.gz
    tar -xzf /tmp/hcloud.tar.gz -C ~/.local/bin hcloud
    chmod +x ~/.local/bin/hcloud
    rm /tmp/hcloud.tar.gz

    info "hcloud installed to ~/.local/bin/hcloud"
}

# Install Rust/Cargo if needed for some tools
install_rust() {
    if ! command -v cargo &> /dev/null; then
        info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
}

# Initialize Neovim plugins if nvim-config exists
init_neovim_plugins() {
    if ! command -v nvim &> /dev/null; then
        warn "Neovim not found, skipping plugin installation"
        return
    fi

    # Check if nvim-config directory exists (relative to script location)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ ! -d "$SCRIPT_DIR/nvim-config" ]; then
        warn "nvim-config directory not found, skipping plugin installation"
        return
    fi

    info "Initializing Neovim plugins..."

    # Neovim plugin installation happens automatically on first launch
    # We'll do a headless sync to pre-install plugins
    nvim --headless +qa 2>/dev/null || true
    sleep 2
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

    info "Neovim plugins initialized"
}

# Main
main() {
    info "Starting dependency installation..."

    # Install Rust/Cargo first (needed for some tools)
    install_rust

    install_packages

    # Initialize Neovim plugins if setup has been run
    # This allows the install script to work standalone or after setup.sh
    if [ -d "$HOME/.config/nvim" ] && [ -L "$HOME/.config/nvim" ]; then
        info "Detected Neovim configuration, initializing plugins..."
        init_neovim_plugins
    fi

    info "Done! Now run ./setup.sh to create symlinks."
}

main "$@"
