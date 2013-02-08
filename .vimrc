syntax on
set autoindent
set smartindent
set number

set tabstop=2
set shiftwidth=2
set expandtab

filetype plugin indent on
call pathogen#runtime_append_all_bundles()
call pathogen#infect()

au BufWritePost *.coffee silent CoffeeMake! -b | cwindow | redraw!
