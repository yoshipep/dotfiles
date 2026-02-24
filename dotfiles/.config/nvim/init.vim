" ============================================================================
" LEADER KEY & BASIC SETTINGS
" ============================================================================

let mapleader = "\<Space>"

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
set noshowmode

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
Plug 'ellisonleao/gruvbox.nvim'

" LSP & Completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'antoinemadec/coc-fzf'

" Syntax & Language Support
Plug 'sheerun/vim-polyglot'
Plug 'nvim-treesitter/nvim-treesitter', { 'branch': 'master', 'do': ':TSUpdate' }
Plug 'bfrg/vim-c-cpp-modern'
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
Plug 'nvim-telescope/telescope.nvim', { 'branch': '0.1.x' }
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'MunifTanjim/nui.nvim'
Plug 'nvim-neo-tree/neo-tree.nvim', { 'branch': 'v3.x' }

" Git Integration
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-obsession'

" UI Enhancements
Plug 'nvim-tree/nvim-web-devicons'
Plug 'vim-airline/vim-airline'
Plug '0xferrous/ansi.nvim'

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

" Custom colors for CoC menu - ensure selected item is visible
func! s:my_colors_setup() abort
  " CoC menu selection - solid orange background with underline
  highlight CocMenuSel ctermbg=208 ctermfg=235 cterm=bold,underline guibg=#ff8700 guifg=#282828 gui=bold,underline
  " Standard Vim popup menu selection
  highlight PmenuSel ctermbg=208 ctermfg=235 cterm=bold guibg=#ff8700 guifg=#282828 gui=bold
endfunc

augroup colorscheme_coc_setup | au!
  au ColorScheme * call s:my_colors_setup()
  au VimEnter * call s:my_colors_setup()
augroup END

" ============================================================================
" SOURCE CONFIGURATION FILES
" ============================================================================

" General Vim configuration
source ~/.config/nvim/functions.vim
source ~/.config/nvim/autocommands.vim
source ~/.config/nvim/keybindings.vim

" Plugin-specific configurations
source ~/.config/nvim/plugins.conf/coc.vim
source ~/.config/nvim/plugins.conf/vim-airline.vim
source ~/.config/nvim/plugins.conf/plugins.vim
