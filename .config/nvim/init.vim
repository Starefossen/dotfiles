set nocompatible "prevent arrow keys from inserting A B C D

" Set the shell to Bash
set shell=/bin/bash   " set shell to bash

" Set Up Pathogen Bundles
execute pathogen#infect('~/.vim/bundle/{}')

" Vim File History
set viminfo='100,n$HOME/.config/nvim/files/info/viminfo

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
autocmd ColorScheme * :highlight LineNr ctermbg=233

" Windows
set splitright        " opens new vertical splits to the right
set splitbelow        " opens new horisontal splits bellow

" Copy and Paste
filetype indent on    " load filetype-specific indent files
set autoindent        " auto indent (remember paste / nopaste)
set smartindent       " smart indentation
set pastetoggle=<F2>  " toggle paste mode with F2
nnoremap <F2> :set invpaste paste?<CR>
nnoremap <F1> :w<CR>

" Tabs and Spaces
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

" Swapping
set dir=.             " save swap files to same directory

" Copy / paste
" https://github.com/neovim/neovim/issues/3702
set cb=unnamed        " enable y => cmd+c
set mouse=            " enable cmd+c in vim

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

" enable zen writing mode
nnoremap <silent> <leader>z :Goyo<CR>

" show warning for non breaking spaces
autocmd VimEnter,BufWinEnter * syn match ErrorMsg " "

" remove trailing white space on save
autocmd BufWritePre * :%s/\s\+$//e

" https://github.com/neovim/neovim/issues/2048
nnoremap <silent> <BS> :TmuxNavigateLeft<cr>

" go specific bindigns
autocmd FileType go nmap <leader>b  <Plug>(go-build)
autocmd FileType go nmap <leader>r  <Plug>(go-run)
autocmd FileType go nmap <leader>t  <Plug>(go-test)

" go auto import on save (fmt)
let g:go_fmt_command = "goimports"

let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1

" Autosave on leave
let g:tmux_navigator_save_on_switch = 1

let g:bufferline_echo = 10 " ingore bufferline line

" fzf search
set rtp+=~/.fzf
nnoremap <c-p> :FZF<cr>

set wildignore+=*/tmp/*,*.so,*.swp,*.zip
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/](\.git|\.hg|\.svn|node_modules|bower_components)$',
  \ 'file': '\v\.(exe|so|dll|pyc)$',
  \ }

function! s:goyo_enter()
  silent !tmux set status off
  silent !tmux list-panes -F '\#F' | grep -q Z || tmux resize-pane -Z
  set nocursorline
  set noshowmode
  set noshowcmd
  set scrolloff=999
  Limelight
endfunction

function! s:goyo_leave()
  silent !tmux set status on
  silent !tmux list-panes -F '\#F' | grep -q Z && tmux resize-pane -Z
  set cursorline
  set showmode
  set showcmd
  set scrolloff=5
  Limelight!
endfunction

autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()

autocmd FileType coffee,js,md autocmd BufWritePre <buffer> :%s/\s\+$//e
autocmd FileType yaml :setlocal sw=2 ts=2 sts=2 tw=100
autocmd FileType python :setlocal sw=4 ts=4 sts=4 tw=120
autocmd FileType gitcommit :setlocal tw=70
autocmd BufRead,BufNewFile,BufEnter Jenkinsfile :setlocal filetype=groovy
