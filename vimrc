syntax on

set lines
set number
set hlsearch
set ignorecase
set incsearch
set autoindent
set smartindent
set cindent
set colorcolumn=80
set wildmenu
set title
set belloff=all

" set shiftwidth=4

set packpath+=~/.vim/pack/.
set encoding=utf-8

colorscheme desert

"Define the current directory as 'path' variable.
" 'path' is used for find command to find files.
set path=$PWD/**

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"				MAPPINGS				      "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""""""
"SERCH"
"""""""

"Go to next match after a grep"
noremap <C-N> :cn<CR>
"Go to preivous match after a grep"
noremap <C-P> :cp<CR>

"do a grep -nr on the word the cursor is on"
nnoremap <C-G> :grep -nr <cword> .<cr>

"Search hovered word in current file"
nnoremap <C-F> :call search(expand('<cword>'))<cr>

"""""""""
"BUFFERS"
"""""""""

"next open buffer"
noremap <C-b> :bn<cr>
"previous open buffer"
noremap <C-i> :bp<cr>

""""""
"TABS"
""""""

"next open tab"
noremap <C-Tab> :tabn<cr>
"previous open buffer"
noremap <C-m> :tabnew<cr>
