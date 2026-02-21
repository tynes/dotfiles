#!/bin/bash

OLD=/tmp/dotfile_backup

if [ ! -d $OLD ]; then
  mkdir -p $OLD
fi

echo "Creating sym links..."

# Get all of the files and use `sed -e` to delete
# lines that match the argument
FILES=`ls -a | grep "^\." \
  | sed \
      -e "1,2d" \
      -e "/\.git$/d" \
      -e "/\.gitmodules$/d" \
      -e "/\.gitignore$/d" \
  | grep -v user
`

for FILE in $FILES
do
  DEST=$HOME/$FILE
  # remove symlinks that already exist
  if [[ -L $DEST ]]; then
    echo "SYMLINK FOUND: $DEST - removing"
    rm -rf $DEST
  fi

  # check if file or directory previously exists
  if [[ -e $DEST || -d $DEST ]]; then
    echo "FOUND: $DEST already exists, backing up to $OLD/$FILE"
    mv -f $DEST $OLD/$FILE
  fi

  CMD="ln -sfn $PWD/$FILE $HOME/$FILE"
  echo "RUNNING: $CMD"
  eval $CMD
done

# handles vscode
if [[ "$(uname)" == 'Darwin' ]]; then
  ln -sf "$PWD/settings.json" "$HOME/Library/Application\ Support/Code/User/settings.json"
fi

# AeroSpace window manager (macOS only)
if [[ "$(uname)" == 'Darwin' ]]; then
  echo "Setting up AeroSpace config..."
  [ -e ~/.aerospace.toml ] && [ ! -L ~/.aerospace.toml ] && mv ~/.aerospace.toml ~/.aerospace.toml.bak && echo "Backed up ~/.aerospace.toml to ~/.aerospace.toml.bak"
  [ -L ~/.aerospace.toml ] && rm ~/.aerospace.toml
  CMD="ln -sf $PWD/aerospace.toml $HOME/.aerospace.toml"
  echo "RUNNING: $CMD"
  eval $CMD
  echo "AeroSpace setup complete!"
fi

# AstroNvim v5 setup
echo "Setting up AstroNvim v5..."

# Backup existing nvim directories
[ -e ~/.config/nvim ] && rm -rf ~/.config/nvim.bak && mv ~/.config/nvim ~/.config/nvim.bak && echo "Backed up ~/.config/nvim to ~/.config/nvim.bak"
[ -e ~/.local/share/nvim ] && mv ~/.local/share/nvim ~/.local/share/nvim.bak && echo "Backed up ~/.local/share/nvim to ~/.local/share/nvim.bak"
[ -e ~/.local/state/nvim ] && mv ~/.local/state/nvim ~/.local/state/nvim.bak && echo "Backed up ~/.local/state/nvim to ~/.local/state/nvim.bak"
[ -e ~/.cache/nvim ] && mv ~/.cache/nvim ~/.cache/nvim.bak && echo "Backed up ~/.cache/nvim to ~/.cache/nvim.bak"

# Create symlink to AstroNvim v5 config
CMD="ln -sfn $PWD/nvim-config $HOME/.config/nvim"
echo "RUNNING: $CMD"
eval $CMD

echo "AstroNvim v5 setup complete!"
echo "Run 'nvim' to start Neovim and install plugins."

# Ghostty terminal setup
echo "Setting up Ghostty terminal config..."

# Ensure .config directory exists
mkdir -p ~/.config

# Backup existing ghostty config if it exists
[ -e ~/.config/ghostty ] && rm -rf ~/.config/ghostty.bak && mv ~/.config/ghostty ~/.config/ghostty.bak && echo "Backed up ~/.config/ghostty to ~/.config/ghostty.bak"

# Create symlink to Ghostty config
CMD="ln -sfn $PWD/config/ghostty $HOME/.config/ghostty"
echo "RUNNING: $CMD"
eval $CMD

echo "Ghostty setup complete!"

# Starship prompt setup
echo "Setting up Starship prompt config..."

# Backup existing starship config if it exists
[ -e ~/.config/starship.toml ] && mv ~/.config/starship.toml ~/.config/starship.toml.bak && echo "Backed up ~/.config/starship.toml to ~/.config/starship.toml.bak"

# Create symlink to Starship config
CMD="ln -sf $PWD/config/starship.toml $HOME/.config/starship.toml"
echo "RUNNING: $CMD"
eval $CMD

echo "Starship setup complete!"

# Jujutsu (jj) setup
echo "Setting up Jujutsu (jj) config..."

# Ensure .config/jj directory exists
mkdir -p ~/.config/jj

# Backup existing jj config if it exists
[ -e ~/.config/jj/config.toml ] && mv ~/.config/jj/config.toml ~/.config/jj/config.toml.bak && echo "Backed up ~/.config/jj/config.toml to ~/.config/jj/config.toml.bak"

# Create symlink to jj config
CMD="ln -sf $PWD/config/jj/config.toml $HOME/.config/jj/config.toml"
echo "RUNNING: $CMD"
eval $CMD

echo "Jujutsu setup complete!"

# Worktrunk setup
echo "Setting up Worktrunk config..."

# Backup existing wt config if it exists
[ -e ~/.config/wt.toml ] && mv ~/.config/wt.toml ~/.config/wt.toml.bak && echo "Backed up ~/.config/wt.toml to ~/.config/wt.toml.bak"

# Create symlink to wt config
CMD="ln -sf $PWD/config/wt.toml $HOME/.config/wt.toml"
echo "RUNNING: $CMD"
eval $CMD

echo "Worktrunk setup complete!"

# Bin directory setup
echo "Setting up bin directory..."

# Backup existing bin directory if it exists and is not a symlink
[ -e ~/bin ] && [ ! -L ~/bin ] && mv ~/bin ~/bin.bak && echo "Backed up ~/bin to ~/bin.bak"

# Remove existing symlink if present
[ -L ~/bin ] && rm ~/bin

# Create symlink to bin directory
CMD="ln -sfn $PWD/bin $HOME/bin"
echo "RUNNING: $CMD"
eval $CMD

echo "Bin directory setup complete!"

# Rust tooling setup
if command -v rustup &> /dev/null; then
  echo "Setting up Rust development tools..."
  rustup component add rust-analyzer
  echo "Rust tooling setup complete!"
else
  echo "rustup not found - skipping rust-analyzer installation"
  echo "Install rustup from https://rustup.rs/ to enable Rust support"
fi

