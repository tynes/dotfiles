" reference here:
" https://vimawesome.com/
" TODO: load plugins specific for certain files

call plug#begin('~/.local/share/nvim/plugged')

" fzf plugin
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim'

" autocomplete
Plug 'roxma/nvim-completion-manager'
Plug 'roxma/nvim-cm-tern', {'do': 'npm install'}

" sidebar
Plug 'scrooloose/nerdtree'

" comment out code easily
Plug 'chrisbra/vim-commentary'

" solarized color scheme
Plug 'altercation/vim-colors-solarized'

" full path fuzzy file, buffer, mru, tag
Plug 'kien/ctrlp.vim'

" show git differences in the gutter
Plug 'airblade/vim-gitgutter'

" surround
Plug 'tpope/vim-surround'

" async linting engine
Plug 'w0rp/ale'

" multiple cursor supprort
Plug 'terryma/vim-multiple-cursors'

" for javascript
Plug 'pangloss/vim-javascript'

" for go
Plug 'fatih/vim-go'

" Initialize plugin system
call plug#end()

" see whitespace
Plug 'ntpeters/vim-better-whitespace'
