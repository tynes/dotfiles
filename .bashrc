if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

for file in $HOME/.bash/*; do
	source $file
done

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
