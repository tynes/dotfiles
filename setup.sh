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

  CMD="ln -sf $PWD/$FILE $HOME/$FILE"
  echo "RUNNING: $CMD"
  eval $CMD
done

# handles vscode
if [[ "$(uname)" == 'Darwin' ]]; then
  ln -sf "$PWD/settings.json" "$HOME/Library/Application\ Support/Code/User/settings.json"
fi

# AstroNvim v5 setup
echo "Setting up AstroNvim v5..."

# Backup existing nvim directories
[ -e ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.bak && echo "Backed up ~/.config/nvim to ~/.config/nvim.bak"
[ -e ~/.local/share/nvim ] && mv ~/.local/share/nvim ~/.local/share/nvim.bak && echo "Backed up ~/.local/share/nvim to ~/.local/share/nvim.bak"
[ -e ~/.local/state/nvim ] && mv ~/.local/state/nvim ~/.local/state/nvim.bak && echo "Backed up ~/.local/state/nvim to ~/.local/state/nvim.bak"
[ -e ~/.cache/nvim ] && mv ~/.cache/nvim ~/.cache/nvim.bak && echo "Backed up ~/.cache/nvim to ~/.cache/nvim.bak"

# Create symlink to AstroNvim v5 config
CMD="ln -sf $PWD/nvim-config $HOME/.config/nvim"
echo "RUNNING: $CMD"
eval $CMD

echo "AstroNvim v5 setup complete!"
echo "Run 'nvim' to start Neovim and install plugins."

# Ghostty terminal setup
echo "Setting up Ghostty terminal config..."

# Ensure .config directory exists
mkdir -p ~/.config

# Backup existing ghostty config if it exists
[ -e ~/.config/ghostty ] && mv ~/.config/ghostty ~/.config/ghostty.bak && echo "Backed up ~/.config/ghostty to ~/.config/ghostty.bak"

# Create symlink to Ghostty config
CMD="ln -sf $PWD/config/ghostty $HOME/.config/ghostty"
echo "RUNNING: $CMD"
eval $CMD

echo "Ghostty setup complete!"
