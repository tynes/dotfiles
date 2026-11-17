#!/bin/bash
# Apply macOS system settings (Dock, Finder, keyboard, hostname).
#
# usage: ./macos.sh [hostname]
#
# Safe to re-run. Pass a hostname to pin the machine name (needs sudo);
# without it the name is left alone. Some settings only take effect after
# logging out and back in.

set -euo pipefail

if [[ "$(uname)" != 'Darwin' ]]; then
  echo "macos.sh: not macOS, skipping" >&2
  exit 0
fi

# --- Hostname ---------------------------------------------------------------
# Without an explicit HostName, macOS takes its name from reverse DNS, so the
# router decides what the prompt shows (e.g. "*.lan"). Pin it instead.
# Stick to a-z, 0-9 and '-': the name is broadcast over Bonjour and DHCP.
if [[ $# -ge 1 ]]; then
  name="$1"
  if [[ ! "$name" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
    echo "macos.sh: hostname must be lowercase letters, digits and '-'" >&2
    exit 1
  fi
  echo "Setting hostname to $name (sudo)..."
  sudo scutil --set HostName "$name"
  sudo scutil --set LocalHostName "$name"
  sudo scutil --set ComputerName "$name"
  dscacheutil -flushcache
fi

# --- Dock -------------------------------------------------------------------
# Dock on the left, hidden until the pointer touches that edge.
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 39

# --- Finder -----------------------------------------------------------------
# Column view in new windows.
defaults write com.apple.finder FXPreferredViewStyle -string clmv

# --- Appearance and input ---------------------------------------------------
# Dark mode (applies after logout).
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark
# Turn off "natural" scrolling (applies after logout).
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# --- Window management ------------------------------------------------------
# No gaps around macOS-tiled windows (AeroSpace handles tiling).
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

# Restart the apps that read these so changes show up now.
killall Dock Finder 2>/dev/null || true

echo "macOS settings applied. Log out and back in for appearance and scrolling."
