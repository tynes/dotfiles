#!/bin/bash

OLD=/tmp/dotfile_backup

if [ ! -d $OLD ]; then
  mkdir -p $OLD
fi

echo "Creating sym links..."

# sed -e "/.*/d" <-- delete lines that match

FILES=`ls -a | grep "^\." \
  | sed \
      -e "1,2d" \
      -e "/\.git$/d" \
      -e "/\.gitmodules$/d" \
      -e "/\.gitignore$/d" \
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

echo "checking for vim plug..."
# check to see if plug exists already, install if not
if [ ! -f $HOME/.local/share/nvim/sit/autoload/plug.vim ]; then
    echo "not found, installing..."
    echo "assuming neovim for installation"
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
else
    echo "vim plug found, skipping installation"
fi

