" autoreload for .vimrc
autocmd! bufwritepost .vimrc source %

" unmap arrow keys in every mode, I have to learn it...
"noremap <Up> <Nop>
"noremap <Down> <Nop>
"noremap <Left> <Nop>
"noremap <Right> <Nop>
"vnoremap <Up> <Nop>
"vnoremap <Down> <Nop>
"vnoremap <Left> <Nop>
"vnoremap <Right> <Nop>
"inoremap <Up> <Nop>
"inoremap <Down> <Nop>
"inoremap <Left> <Nop>
"inoremap <Right> <Nop>

" while I like the mouse in gvim, I don't want to move the cursor with it
set mouse=c

" remap the <Leader>
let mapleader = ","

" remove highlight from last search
noremap <C-n> :nohl<CR>
vnoremap <C-n> :nohl<CR>
inoremap <C-n> :nohl<CR>

" remap window movement
map <c-h> <c-w>h
map <c-j> <c-w>j
map <c-k> <c-w>k
map <c-l> <c-w>l

" sorting with <Leader>s \o/
noremap <Leader>s :sort<CR>

" block indentation will not loose focus
vnoremap < <gv
vnoremap > >gv

" make gvim usable
" T -> toolbar
" i -> vim icon 
set guioptions=aegmt

" Pathogen load
filetype off

call pathogen#infect()
call pathogen#helptags()

filetype plugin indent on
syntax on

" Show whitespace
" MUST be inserted BEFORE the colorscheme command
autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red
au InsertLeave * match ExtraWhitespace /\s\+$/

" colorscheme
set background=dark
colorscheme wombat256
set guifont=Source\ Code\ Pro\ Medium\ 9


" Showing line numbers and length
set number  " show line numbers
set tw=79   " width of document (used by gd)
set nowrap  " don't automatically wrap on load
set fo-=t   " don't automatically wrap text when typing
"set colorcolumn=80
"highlight ColorColumn ctermbg=233

" Real programmers don't use TABs but spaces
set tabstop=4
set softtabstop=4
set shiftwidth=4
set shiftround
set expandtab


" Make search case insensitive
set hlsearch
set incsearch
set ignorecase
set smartcase

set nocompatible
set encoding=utf-8

set autoindent

noremap <C-c>f <Leader>f
noremap <C-c>g <Leader>g

let g:pymode_rope_guess_project = 0
let g:pymode_rope_vim_completion = 1
let g:pymode_folding = 0
set completeopt=menu,menuone,longest
" imap <tab><tab> <c-x><c-o>
"
autocmd Filetype java setlocal omnifunc=javacomplete#Complete
let g:SuperTabDefaultCompletionType = 'context'

" CtrlP
let g:ctrlp_working_path_mode = 'rc'

" python_editing.vim (http://www.vim.org/scripts/script.php?script_id=1494)
set nofoldenable

" cursor stays away from top and button 5 lines always
set so=5
