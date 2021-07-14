for file in `ls ~/.bash`; do
	source ~/.bash/$file
done

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/Projects/google-cloud-sdk/path.bash.inc" ]; then . "$HOME/Projects/google-cloud-sdk/path.bash.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/Projects/google-cloud-sdk/completion.bash.inc" ]; then . "$HOME/Projects/google-cloud-sdk/completion.bash.inc"; fi

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
