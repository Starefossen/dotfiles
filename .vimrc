set nocompatible "prevent arrow keys from inserting A B C D

" Set the shell to Bash
set shell=/bin/bash   " set shell to bash

" Set Up Pathogen Bundles
call pathogen#infect('~/.vim/bundle/{}')

" Vim File History
set viminfo='100,n$HOME/.vim/files/info/viminfo

" UI
set vb t_vb=          " disbale visual bell
set background=dark   " set background to dark

set number            " show line numbers
set textwidth=80      " max text width (will force new line)
set cursorline        " highlight current line
set showmode          " show the current mode
set showcmd           " show last command
set scrolloff=5       " start scolling lines 5 from top or bottom

" seoul256 theme
let g:seoul256_background = 233
color seoul256
" highlight LineNr ctermbg=233

" Windows
set splitright        " opens new vertical splits to the right
set splitbelow        " opens new horisontal splits bellow

" Copy and Paste
filetype indent on    " load filetype-specific indent files
set autoindent        " auto indent (remember paste / nopaste)
set smartindent       " smart indentation

" Tags and Spaces
set tabstop=2         " tabs should insert 2 spaces
set shiftwidth=2      " tabs should be 2 spaces long
set expandtab         " replace tabs with spaces (insert)

" Folding
set foldmethod=syntax " fold based on syntax
set foldlevelstart=3  " start new folds on level 3
set foldnestmax=3     " end new folds on level 3

" Open / Close Folds
nnoremap <space> za

" Searchng
set incsearch         " search as characters are entered
set hlsearch          " highligh search results
set smartcase         " smart casing search

" toggle gundo
nnoremap <leader>u :GundoToggle<CR>

" Disable Arrow Keys
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>
imap <up> <nop>
imap <down> <nop>
imap <left> <nop>
imap <right> <nop>

" leader key is comma ","
let mapleader=","

" escape is jj
inoremap jj <esc>

" <leader><Space> will turn of search matches
nnoremap <leader><Space> :nohlsearch<Bar>:echo<CR>

" Better up / down Movement
nnoremap j gj
nnoremap k gk

" move to beginning/end of line
nnoremap B ^
nnoremap E $

" $/^ doesn't do anything
nnoremap $ <nop>
nnoremap ^ <nop>

" edit vimrc and load vimrc bindings
nnoremap <leader>ev :vsp $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

" next (<leader>n) and previous (<leader>p) tab
nnoremap <silent> <leader>n gt
nnoremap <silent> <leader>p gT

" paragraph formating
nnoremap <silent> <leader>f gqip

" show warning for non breaking spaces
autocmd VimEnter,BufWinEnter * syn match ErrorMsg " "

" remove trailing white space on save
autocmd BufWritePre * :%s/\s\+$//e

" Autosave on leave
let g:tmux_navigator_save_on_switch = 1

let g:bufferline_echo = 10 " ingore bufferline line
set wildignore+=*/tmp/*,*.so,*.swp,*.zip
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/](\.git|\.hg|\.svn|node_modules|bower_components)$',
  \ 'file': '\v\.(exe|so|dll|pyc)$',
  \ }

augroup json_autocmd
  autocmd!
  autocmd FileType json set autoindent
  autocmd FileType json set formatoptions=tcq2l
  autocmd FileType json set textwidth=78 shiftwidth=2
  autocmd FileType json set softtabstop=2 tabstop=8
  autocmd FileType json set expandtab
  autocmd FileType json set foldmethod=syntax
augroup END

autocmd FileType coffee,js,md autocmd BufWritePre <buffer> :%s/\s\+$//e
autocmd FileType yaml :setlocal sw=4 ts=4 sts=4 tw=100
autocmd FileType python :setlocal sw=4 ts=4 sts=4 tw=120
