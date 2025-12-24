" ============================================================================
" LEADER KEY & BASIC SETTINGS
" ============================================================================

let mapleader = ","

" UI Settings
set number
set relativenumber
set mouse=a
set showcmd
set encoding=utf-8
set showmatch
syntax enable
set nospell
set list
set listchars=eol:⏎,tab:␉·,trail:␠,nbsp:⎵

" Indentation & Formatting
filetype plugin indent on
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set tw=120

" ============================================================================
" PLUGIN DECLARATIONS
" ============================================================================

call plug#begin('~/.vim/plugged')

" Themes
Plug 'pR0Ps/molokai-dark'
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
Plug 'rebelot/kanagawa.nvim'
Plug 'navarasu/onedark.nvim'
Plug 'Mofiqul/vscode.nvim'
Plug 'Dracula/vim', { 'as': 'dracula' }
Plug 'tiagovla/tokyodark.nvim'

" LSP & Completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'antoinemadec/coc-fzf'

" Syntax & Language Support
Plug 'sheerun/vim-polyglot'
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
Plug 'ekalinin/Dockerfile.vim'
Plug 'lervag/vimtex'

" Code Tools
Plug 'Raimondi/delimitMate'
Plug 'ntpeters/vim-better-whitespace'
Plug 'tpope/vim-commentary'
Plug 'sbdchd/neoformat'
Plug 'kkoomen/vim-doge', { 'do': { -> doge#install() } }
Plug 'stsewd/isort.nvim', { 'do': ':UpdateRemotePlugins' }

" Navigation & Search
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'scrooloose/nerdtree'

" Git Integration
Plug 'tpope/vim-fugitive'

" UI Enhancements
Plug 'ryanoasis/vim-devicons'
Plug 'vim-airline/vim-airline'

call plug#end()

" ============================================================================
" THEME & COLORSCHEME
" ============================================================================

" Load theme from config file, default to molokai-dark
let s:theme_file = expand('~/.vim_theme')
let s:selected_theme = 'molokai-dark'

if filereadable(s:theme_file)
  let s:selected_theme = trim(readfile(s:theme_file)[0])
endif

execute 'colorscheme ' . s:selected_theme

" Highlight ColorColumn at 120 characters
call matchadd('ColorColumn', '\%120v', 120)

" Custom colors for CoC menu
func! s:my_colors_setup() abort
  highlight CocMenuSel ctermbg=235
endfunc

augroup colorscheme_coc_setup | au!
  au VimEnter * call s:my_colors_setup()
augroup END

" ============================================================================
" PLUGIN CONFIGURATIONS
" ============================================================================

" Source plugin-specific configs
source ${HOME}/.config/nvim/plugins.conf/coc.vim
source ${HOME}/.config/nvim/plugins.conf/vim-airline.vim

" --- Neoformat ---
let g:neoformat_clangformat_path = '/usr/bin/clang-format'
let g:neoformat_clangformat = {
        \ 'exe': 'clang-format',
        \ 'args': ['-style=file', '-fallback-style=Google'],
        \ 'stdin': 1,
        \ }
let g:neoformat_enabled_c = ['clangformat']

let g:neoformat_tex_latexindent = {
            \ 'exe': 'latexindent',
            \ 'args': ['-m'],
            \ 'stdin': 1
            \ }

" --- Doge (Documentation Generator) ---
let g:doge_doc_standard_python = 'sphinx'
let g:doge_doc_standard_c = 'kernel_doc'
let g:doge_doc_standard_cpp = 'doxygen_javadoc'
let g:doge_doc_standard_sh = 'google'

" --- Python & Isort ---
let g:python3_host_prog = '/usr/bin/python3'
let g:isort_command = 'isort'

" --- Vimtex ---
let g:vimtex_view_general_viewer = 'evince'
let g:vimtex_compiler_method = 'latexmk'

" --- Airline ---
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#syntastic#enabled = 1
let g:airline#extensions#tabline#buffer_idx_mode = 1

" --- C/C++ ---
let g:c_syntax_for_h = 1

" --- NERDTree ---
let NERDTreeQuitOnOpen=1

" --- CoC ---
let g:coc_snippet_next = '<tab>'

" --- Telescope ---
lua << EOF
require('telescope').setup{
  defaults = {
    file_ignore_patterns = { "node_modules", ".git/", "*.o", "*.a", "*.so" },
    layout_strategy = 'horizontal',
    layout_config = {
      horizontal = {
        preview_width = 0.55,
      },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    }
  }
}
require('telescope').load_extension('fzf')
EOF

" ============================================================================
" FUNCTIONS
" ============================================================================

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

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" ============================================================================
" AUTOCOMMANDS
" ============================================================================

" Restore cursor shape on exit
augroup RestoreCursorShapeOnExit
    autocmd!
    autocmd VimLeave * set guicursor=a:ver35-blinkon1
augroup END

" C/C++ settings
autocmd FileType c setlocal shiftwidth=8 tabstop=8 softtabstop=8 expandtab commentstring=//\ %s
autocmd FileType cpp setlocal shiftwidth=8 tabstop=8 softtabstop=8 expandtab  commentstring=//\ %s
autocmd BufNewFile *.h call AddHeaderGuards()

" LaTeX settings
autocmd FileType tex setlocal spell
autocmd FileType tex set fo-=t

" Markdown settings
autocmd FileType markdown setlocal spell

" Text files settings
autocmd FileType text setlocal spell

" CSS settings
autocmd FileType css setl iskeyword+=-

" Makefile settings (use real tabs)
if has("autocmd")
    autocmd FileType make set noexpandtab
    autocmd FileType make set tabstop=4 shiftwidth=4
endif

" Custom filetypes
autocmd BufRead,BufNewFile *.lds set ft=ld
autocmd BufRead,BufNewFile *.s setfiletype asm
autocmd BufRead,BufNewFile *.S setfiletype asm

" CoC format on save
augroup CocFormatOnSave
  autocmd!
  autocmd BufWritePre * silent! call CocAction('format')
augroup END

" ============================================================================
" KEYBINDINGS
" ============================================================================

" --- File Operations ---
nnoremap <F5> :e <CR>                  " Refresh current file
nnoremap <C-S> :w <CR>                 " Write current file
nnoremap <C-X> :q <CR>                 " Quit VIM
nnoremap <M-w> :bwipeout <CR>          " Close current buffer

" --- Tab Navigation ---
nnoremap <M-J> :tabNext <CR>           " Move to next tab
nnoremap <M-K> :tabprevious <CR>       " Move to previous tab
nnoremap <M-Q> :tabclose <CR>          " Close current tab

" --- Buffer Navigation ---
nnoremap <silent> <C-J> :bprevious <CR>
nnoremap <silent> <C-K> :bnext <CR>
nmap <leader>1 <Plug>AirlineSelectTab1
nmap <leader>2 <Plug>AirlineSelectTab2
nmap <leader>3 <Plug>AirlineSelectTab3
nmap <leader>4 <Plug>AirlineSelectTab4
nmap <leader>5 <Plug>AirlineSelectTab5
nmap <leader>6 <Plug>AirlineSelectTab6
nmap <leader>7 <Plug>AirlineSelectTab7
nmap <leader>8 <Plug>AirlineSelectTab8
nmap <leader>9 <Plug>AirlineSelectTab9

" --- Window/Split Navigation ---
nnoremap <leader>vb :ls<cr>:vertical sb<space>
nnoremap <silent> <M-up> :wincmd k<CR>
nnoremap <silent> <M-down> :wincmd j<CR>
nnoremap <silent> <M-left> :wincmd h<CR>
nnoremap <silent> <M-right> :wincmd l<CR>

" --- Word Manipulation ---
inoremap <M-d> <esc>"_ciw              " Insert mode: delete current word
nnoremap <M-d> "_diw                   " Normal mode: delete current word
inoremap <M-BS> <space><esc>"_cb<Del>  " Forward kill word (insert mode)
inoremap <M-Del> <space><esc>l"_cw<BS> " Backward kill word (insert mode)
nnoremap <M-BS> "_db                   " Forward kill word (normal mode)
nnoremap <M-Del> "_de                  " Backward kill word (normal mode)
nnoremap _ diw                         " Remove word after search
nnoremap Q d0                          " Remove backwards to start of line

" --- Search ---
nnoremap <C-F> *                       " Search next instance of current word
nnoremap <C-D> #                       " Search previous instance of current word

" --- Clipboard-friendly Delete/Paste ---
nnoremap <leader>d "_d                 " Delete without yanking
vnoremap <leader>d "_d                 " Delete without yanking (visual)
vnoremap <leader>p "_dP                " Paste without yanking

" --- NERDTree ---
nnoremap <silent> <C-G> :NERDTreeFind<CR>
nnoremap <silent> <C-A> :NERDTreeToggle<CR>

" --- Commentary ---
nnoremap <space>/ :Commentary<CR>
vnoremap <space>/ :Commentary<CR>

" --- Documentation Generator (Doge) ---
nmap <silent> <Leader>d <Plug>(doge-generate)

" --- LaTeX ---
nnoremap <F2> :set spelllang=en_us<CR>
nnoremap <F3> :set spelllang=es_es<CR>
nnoremap <leader>c <Plug>(vimtex-compile)
nnoremap <leader>v :VimtexView<CR>

" --- Telescope ---
nnoremap <leader>f <cmd>Telescope find_files<cr>
nnoremap <leader>g <cmd>Telescope live_grep<cr>

" --- CoC Tab Completion & Snippets ---
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ CheckBackspace() ? "\<TAB>" :
      \ coc#refresh()
