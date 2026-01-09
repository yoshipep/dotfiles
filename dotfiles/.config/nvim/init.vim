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
Plug 'ellisonleao/gruvbox.nvim'

" LSP & Completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'antoinemadec/coc-fzf'

" Syntax & Language Support
Plug 'sheerun/vim-polyglot'
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
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

" UI Enhancements
Plug 'nvim-tree/nvim-web-devicons'
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

" Prettier for markdown formatting
let g:neoformat_enabled_markdown = ['prettier']
let g:neoformat_markdown_prettier = {
            \ 'exe': 'prettier',
            \ 'args': ['--parser', 'markdown', '--prose-wrap', 'preserve'],
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

" --- C/C++ ---
let g:c_syntax_for_h = 1

let g:cpp_function_highlight = 1

let g:cpp_attributes_highlight = 1

let g:cpp_member_highlight = 1

let g:cpp_type_name_highlight = 1

let g:cpp_operator_highlight = 0

let g:cpp_builtin_types_as_statement = 0

let g:cpp_simple_highlight = 1

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

" --- nvim-web-devicons ---
lua << EOF
require('nvim-web-devicons').setup({
  default = true,  -- Enable default icons
})
EOF

" --- Neo-tree ---
lua << EOF
require('neo-tree').setup({
  close_if_last_window = true,  -- Close Neo-tree if it's the last window
  popup_border_style = "rounded",
  enable_git_status = true,
  enable_diagnostics = true,
  filesystem = {
    follow_current_file = {
      enabled = false,  -- Don't auto-focus current file
    },
    hijack_netrw_behavior = "open_default",
    use_libuv_file_watcher = true,  -- Auto-refresh on file changes
  },
  window = {
    position = "left",
    width = 30,
    mappings = {
      ["<space>"] = "none",  -- Disable space (we use it for other things)
      ["<cr>"] = "open",
      ["o"] = "open",
    },
  },
  event_handlers = {
    {
      event = "file_opened",
      handler = function(file_path)
        require("neo-tree.command").execute({ action = "close" })
      end
    },
  },
  default_component_configs = {
    indent = {
      padding = 0,
    },
  },
})
EOF

" --- Treesitter ---
lua << EOF
require('nvim-treesitter').setup {
  -- Install parsers for your languages
  ensure_installed = {
    "c", "cpp", "python", "bash", "lua", "vim", "vimdoc",
    "markdown", "markdown_inline", "latex", "rust",
    "json", "yaml", "toml", "html", "css", "javascript",
    "make", "cmake"
  },

  -- Install parsers synchronously (only applied to ensure_installed)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  auto_install = true,

  highlight = {
    enable = true,              -- Enable treesitter-based highlighting
    additional_vim_regex_highlighting = false,  -- Disable old regex highlighting
  },

  indent = {
    enable = true               -- Better indentation
  },
}
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

function! DetectIndentation()
    " Skip if buffer is empty or very small
    if line('$') < 5
        return
    endif

    " Count lines with leading tabs vs spaces
    let l:tab_count = 0
    let l:space_count = 0
    let l:space_indent_sizes = {}

    " Sample up to 200 lines for performance
    let l:max_lines = min([line('$'), 200])

    for l:lnum in range(1, l:max_lines)
        let l:line = getline(l:lnum)

        " Skip empty lines and lines without indentation
        if l:line =~ '^\s*$' || l:line !~ '^\s'
            continue
        endif

        " Check if line starts with tab
        if l:line =~ '^\t'
            let l:tab_count += 1
        " Check if line starts with spaces
        elseif l:line =~ '^ '
            let l:space_count += 1

            " Detect space indent width (2, 4, or 8 spaces)
            let l:indent = matchstr(l:line, '^ \+')
            let l:indent_len = len(l:indent)

            " Track indent sizes
            if l:indent_len > 0
                let l:space_indent_sizes[l:indent_len] = get(l:space_indent_sizes, l:indent_len, 0) + 1
            endif
        endif
    endfor

    " If we found indented lines, adjust settings
    if l:tab_count > 0 || l:space_count > 0
        " Use tabs if tabs are more common
        if l:tab_count > l:space_count
            setlocal noexpandtab
            setlocal tabstop=8
            setlocal shiftwidth=8
        " Use spaces if spaces are more common
        else
            setlocal expandtab

            " Detect the most common indent width
            let l:common_width = 4  " default
            let l:max_occurrences = 0

            for [l:width, l:count] in items(l:space_indent_sizes)
                " Check for common widths: 2, 4, 8
                if (l:width == 2 || l:width == 4 || l:width == 8) && l:count > l:max_occurrences
                    let l:common_width = l:width
                    let l:max_occurrences = l:count
                endif
            endfor

            execute 'setlocal tabstop=' . l:common_width
            execute 'setlocal shiftwidth=' . l:common_width
            execute 'setlocal softtabstop=' . l:common_width
        endif
    endif
endfunc

" ============================================================================
" AUTOCOMMANDS
" ============================================================================

" Restore cursor shape on exit
augroup RestoreCursorShapeOnExit
    autocmd!
    autocmd VimLeave * set guicursor=a:ver35-blinkon1
augroup END

" Auto-detect indentation (tabs vs spaces)
augroup DetectIndent
    autocmd!
    autocmd BufReadPost * call DetectIndentation()
augroup END

" Assembly filetype detection
autocmd BufNewFile,BufRead *.s,*.S,*.asm set filetype=asm

" C/C++ settings
autocmd FileType c setlocal commentstring=//\ %s
autocmd FileType cpp setlocal commentstring=//\ %s
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

" --- Configuration ---
nnoremap <leader>s :edit $MYVIMRC<CR>  " Edit init.vim settings
nnoremap <leader>r :source $MYVIMRC<CR>  " Reload init.vim configuration
nnoremap <leader>k :execute 'silent !tmux split-window -v "cppman ' . shellescape(expand('<cword>')) . '"'<CR>:redraw!<CR>  " Open cppman in bottom tmux pane
vnoremap <leader>k y:execute 'silent !tmux split-window -v "cppman ' . shellescape(@") . '"'<CR>:redraw!<CR>  " Open cppman in bottom tmux pane
vnoremap <leader>cs <Plug>(coc-convert-snippet)  " Create snippet from selected text

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

" --- Neo-tree ---
nnoremap <silent> <C-A> :Neotree toggle<CR>
nnoremap <silent> <C-G> :Neotree reveal<CR>

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
