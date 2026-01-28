# My Dotfiles

These are my personal dotfiles for setting up a consistent development environment across different machines. They are opinionated and tailored to my workflow, but feel free to use them as a reference or starting point for your own setup.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/tynes/dotfiles.git ~/dotfiles
   ```
2. Run the setup script:
   ```bash
   cd ~/dotfiles
   ./setup.sh
   ```

The setup script will back up your existing dotfiles to `/tmp/dotfile_backup` and then create symlinks to the files in this repository.

## Compatibility

These dotfiles are tested and known to work on macOS (using `homebrew`)
and sort of debian. arch linux support planned for the future.
Apple silicon is just too good unfortunately.
