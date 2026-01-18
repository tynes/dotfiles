# Source environment setup (runs once per login)
if [ -f ~/.profile ]; then
	source ~/.profile
fi

# Source interactive shell configuration
if [ -f ~/.bashrc ]; then
	source ~/.bashrc
fi
