" ============================================================================
" KEYBINDINGS
" ============================================================================

" --- File Operations ---
nnoremap <F5> :e <CR>                  " Refresh current file
nnoremap <C-S> :w <CR>                 " Write current file
nnoremap <C-X> :q <CR>                 " Quit VIM
nnoremap <C-N> :enew <CR>              " Open new buffer
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
