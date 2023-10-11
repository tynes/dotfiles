if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

for file in $HOME/.bash/*; do
	source $file
done
