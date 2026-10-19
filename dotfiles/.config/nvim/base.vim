" Loaded by init.lua after lazy.nvim has loaded the plugins (see lua/plugin_specs.lua).
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

" Highlights that themes may override: re-applied on every colorscheme load
func! s:my_colors_setup() abort
  " Completion menu selection (blink.cmp links its selection to PmenuSel)
  highlight PmenuSel ctermbg=208 ctermfg=235 cterm=bold guibg=#ff8700 guifg=#282828 gui=bold
  " Darken inactive preprocessor regions (#ifdef blocks that won't compile)
  highlight InactiveRegion ctermfg=243 guifg=#666666
endfunc

augroup colorscheme_setup | au!
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

lua require('lsp_config')
lua require('completion')
lua require('markview_config')
lua require('mkdnflow_config')

" Plugin-specific configurations
source ~/.config/nvim/plugins.conf/plugins.vim
lua require('telescope_config')
lua require('devicons_config')
lua require('neotree_config')
lua require('treesitter_config')
lua require('ansi_config')
lua require('gitsigns_config')
lua require('todo_comments_config')
