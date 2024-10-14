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

# TODO: make new neovim setup
# NVIM_CONFIG=$HOME/.config/nvim
# USER_NVIM_CONFIG=$NVIM_CONFIG/lua/user
# if [ ! -f $HOME/.config/nvim/init.lua ]; then
#   echo "Installing AstroNvim"
#   git clone --depth 1 https://github.com/AstroNvim/template $NVIM_CONFIG
# fi

# if [[ -L $USER_NVIM_CONFIG ]]; then
#   unlink $USER_NVIM_CONFIG
# fi

# CMD="ln -sf "$PWD/user" $USER_NVIM_CONFIG"
#echo "RUNNING: $CMD"
#eval $CMD
