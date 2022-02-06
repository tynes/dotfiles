" reference here:
" https://vimawesome.com/
" TODO: load plugins specific for certain files
"

call plug#begin('~/.local/share/nvim/plugged')

" fzf plugin
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim'

" autocomplete
" Plug 'ncm2/ncm2'
" Plug 'roxma/nvim-yarp'
" enable ncm2 for all buffers
" autocmd BufEnter * call ncm2#enable_for_buffer()

Plug 'ncm2/ncm2-bufword'
Plug 'ncm2/ncm2-path'
Plug 'ncm2/ncm2-syntax' | Plug 'Shougo/neco-syntax'

if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif

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

" async linting engine
Plug 'w0rp/ale'

" multiple cursor supprort
Plug 'terryma/vim-multiple-cursors'

" for javascript
Plug 'pangloss/vim-javascript'

" for typescript
Plug 'HerringtonDarkholme/yats.vim'

" for go
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

" for python
Plug 'hdima/python-syntax'

" language server support
Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash install.sh',
    \ }

" see whitespace
Plug 'ntpeters/vim-better-whitespace'

" solidity syntax
Plug 'tomlion/vim-solidity'

" Initialize plugin system
call plug#end()

