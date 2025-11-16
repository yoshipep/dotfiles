let mapleader = ","

set number
set mouse=a
set showcmd
set encoding=utf-8
set showmatch
syntax enable
set nospell

" Restore cursor when exiting vim.
augroup RestoreCursorShapeOnExit
    autocmd!
    autocmd VimLeave * set guicursor=a:ver35-blinkon1
augroup END

set list
set listchars=eol:⏎,tab:␉·,trail:␠,nbsp:⎵

source ${HOME}/.config/nvim/plugins.conf/coc.vim
source ${HOME}/.config/nvim/plugins.conf/vim-airline.vim
filetype plugin indent on
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set tw=120
set relativenumber

function! AddHeaderGuards()
    " Get the filename without extension
    let l:filename = expand('%:t:r')
    let l:guard = toupper(l:filename)
    " Insert the header guard at the top of the file
    execute 'normal! gg'
    call append(0, '#ifndef ' . l:guard . '_H_')
    call append(1, '#define ' . l:guard . '_H_')
    call append(2, '')
    call append('$', '#endif // ' . l:guard . '_H_')
endfunc

autocmd FileType c setlocal shiftwidth=8 tabstop=8 softtabstop=8 expandtab commentstring=//\ %s
autocmd FileType cpp setlocal shiftwidth=8 tabstop=8 softtabstop=8 expandtab  commentstring=//\ %s
" Trigger the function only whenever a new .h file is created
autocmd BufNewFile *.h call AddHeaderGuards()
autocmd FileType tex setlocal spell spelllang=es_es
autocmd FileType tex set fo-=t
autocmd FileType tex nnoremap <leader>g :Neoformat <CR>
autocmd FileType css setl iskeyword+=-
autocmd FileType css nnoremap <leader>g :CocCommand prettier.formatFile<CR>
autocmd FileType typescript nnoremap <leader>g :CocCommand prettier.formatFile<CR>
autocmd FileType html nnoremap <leader>g :CocCommand prettier.formatFile<CR>
autocmd BufRead,BufNewFile *.lds set ft=ld
autocmd BufRead,BufNewFile *.s setfiletype asm
autocmd BufRead,BufNewFile *.S setfiletype asm

set expandtab

if has("autocmd")
    " If the filetype is Makefile then we need to use tabs
    " So do not expand tabs into space.
    autocmd FileType make set noexpandtab
    autocmd FileType make set tabstop=4 shiftwidth=4
endif

call plug#begin('~/.vim/plugged')

" Themes
Plug 'pR0Ps/molokai-dark'

Plug 'neoclide/coc.nvim', {'branch': 'release'}

Plug 'sheerun/vim-polyglot'

Plug 'Raimondi/delimitMate'

Plug 'ntpeters/vim-better-whitespace'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }

Plug 'junegunn/fzf.vim'

Plug 'antoinemadec/coc-fzf'

Plug 'tpope/vim-fugitive'

Plug 'tpope/vim-commentary'

Plug 'scrooloose/nerdtree'

Plug 'ryanoasis/vim-devicons'

Plug 'vim-airline/vim-airline'

Plug 'sbdchd/neoformat'

Plug 'kkoomen/vim-doge', { 'do': { -> doge#install() } }

Plug 'stsewd/isort.nvim', { 'do': ':UpdateRemotePlugins' }

Plug 'lervag/vimtex'

Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }

call plug#end()

" Highlight ColorColumn ctermbg=magenta
call matchadd('ColorColumn', '\%120v', 120)

" Neoformat config for clang-format
let g:neoformat_clangformat_path = '/usr/bin/clang-format'
" Set the default style for clang-format to the Linux kernel coding style
let g:neoformat_clangformat = {
        \ 'exe': 'clang-format',
        \ 'args': ['-style=file', '-fallback-style=Google'],
        \ 'stdin': 1,
        \ }
let g:neoformat_enabled_c = ['clangformat']

" Latexindent configuration
let g:neoformat_tex_latexindent = {
            \ 'exe': 'latexindent',
            \ 'args': ['-m'],
            \ 'stdin': 1
            \ }

" Documentation Generator language options
let g:doge_doc_standard_python = 'sphinx'

"Standard documentation for c files
let g:doge_doc_standard_c = 'kernel_doc'

"Standard documentation for cpp files
let g:doge_doc_standard_cpp = 'doxygen_javadoc'

"Standard documentation for sh files
let g:doge_doc_standard_sh = 'google'

let g:isort_command = 'isort'

let g:python3_host_prog = '/usr/bin/python3'

" Vimtex Config
let g:vimtex_view_general_viewer = 'evince'

let g:vimtex_compiler_method = 'latexmk'

" Commentary configuration
nnoremap <space>/ :Commentary<CR>
vnoremap <space>/ :Commentary<CR>

" Airline config
let g:airline#extensions#tabline#enabled = 1

let g:airline#extensions#branch#enabled = 1

let g:airline#extensions#syntastic#enabled = 1

let g:airline#extensions#tabline#buffer_idx_mode = 1

nmap <leader>1 <Plug>AirlineSelectTab1
nmap <leader>2 <Plug>AirlineSelectTab2
nmap <leader>3 <Plug>AirlineSelectTab3
nmap <leader>4 <Plug>AirlineSelectTab4
nmap <leader>5 <Plug>AirlineSelectTab5
nmap <leader>6 <Plug>AirlineSelectTab6
nmap <leader>7 <Plug>AirlineSelectTab7
nmap <leader>8 <Plug>AirlineSelectTab8
nmap <leader>9 <Plug>AirlineSelectTab9

" Treat .h files as c files, not cpp
let g:c_syntax_for_h = 1

" NERDTREE Configuracion
let NERDTreeQuitOnOpen=1
nnoremap <silent> <C-G> :NERDTreeFind<CR>
nnoremap <silent> <C-A> :NERDTreeToggle<CR>

" Theme Config
set notermguicolors
set background=dark
colorscheme molokai-dark

" Custom colors CoC
func! s:my_colors_setup() abort
  highlight CocMenuSel ctermbg=235
endfunc

augroup colorscheme_coc_setup | au!
  au VimEnter * call s:my_colors_setup()
augroup END

" ********************* KEYBINDINGS ************************

nnoremap <F5> :e <CR> |" Refresh current file
nnoremap <C-S> :w <CR> |" Write current file
nnoremap <C-X> :q <CR> |" Quit VIM
nnoremap <M-w> :bwipeout <CR> |" Close current buffer

" Navigation throug tabs
nnoremap <M-J> :tabNext <CR> |" Move to next tab
nnoremap <M-K> :tabprevious <CR> |" Move to previous tab
nnoremap <M-Q> :tabclose <CR> |" Close current tab

" Delete current word
inoremap <M-d> <esc>"_ciw |" Insert mode delete current word
nnoremap <M-d> "_diw |" Normal mode delete current word

" Backward kill word and regular kill word
inoremap <M-BS> <space><esc>"_cb<Del> |" FKW insert mode
inoremap <M-Del> <space><esc>l"_cw<BS>|" BKW insert mode
nnoremap <M-BS> "_db |" FKW insert mode
nnoremap <M-Del> "_de |" BKW insert mode

" Change between open buffers
nnoremap <silent> <C-J> :bprevious <CR>
nnoremap <silent> <C-K> :bnext <CR>

" Splitting vim visor using a buffer from selection
nnoremap <leader>vb :ls<cr>:vertical sb<space>
" Use ctrl-[hjkl] to select the active split!
nnoremap <silent> <M-up> :wincmd k<CR> |" Up
nnoremap <silent> <M-down> :wincmd j<CR> |" Down
nnoremap <silent> <M-left> :wincmd h<CR> |" Left
nnoremap <silent> <M-right> :wincmd l<CR> |" Right

" Delete without yanking to avoid losing contents in clipboard
nnoremap <leader>d "_d
vnoremap <leader>d "_d

" Replace currently selected text with default register
" without yanking it to avoid losing contents in clipboard when pasting
vnoremap <leader>p "_dP

nnoremap <C-F> * |" Search next instance of current word in document
nnoremap <C-D> # |" Search previous instance of current word in document

" Documentation Generator mappings
nmap <silent> <Leader>d <Plug>(doge-generate)

" Latex spelling
nnoremap <F2> :set spelllang=en_us<CR>
nnoremap <F3> :set spelllang=es_es<CR>
nnoremap <leader>c <Plug>(vimtex-compile)
nnoremap <leader>v :VimtexView<CR>
" Remove a word after <ctrl><f|d>
nnoremap _ diw
" Remove backwards to the start of the line
nnoremap Q d0

" Use Tab for snippet expansion and placeholder navigation
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ CheckBackspace() ? "\<TAB>" :
      \ coc#refresh()

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<tab>'

augroup CocFormatOnSave
  autocmd!
  autocmd BufWritePre * silent! call CocAction('format')
augroup END
