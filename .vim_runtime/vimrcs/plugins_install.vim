" reference here:
" https://vimawesome.com/
" TODO: load plugins specific for certain files
"

call plug#begin('~/.local/share/nvim/plugged')

" fzf plugin
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim'

" autocomplete
Plug 'ncm2/ncm2'
Plug 'roxma/nvim-yarp'

" enable ncm2 for all buffers
autocmd BufEnter * call ncm2#enable_for_buffer()

Plug 'ncm2/ncm2-bufword'
Plug 'ncm2/ncm2-path'
Plug 'ncm2/ncm2-syntax' | Plug 'Shougo/neco-syntax'

" sidebar
Plug 'scrooloose/nerdtree', { 'branch': 'master' }

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
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

" Initialize plugin system
call plug#end()

" see whitespace
Plug 'ntpeters/vim-better-whitespace'
