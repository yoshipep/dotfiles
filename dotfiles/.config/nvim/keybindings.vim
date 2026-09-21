" ============================================================================
" KEYBINDINGS
" ============================================================================

" --- File Operations ---
" Refresh current file
nnoremap <F5> :e <CR>
" Write current file
nnoremap <C-S> :w <CR>
" Quit VIM
nnoremap <C-X> :q <CR>
nnoremap <C-n> :enew<CR>
" Close current buffer; <M-W> discards changes
nnoremap <M-w> :bwipeout <CR>
nnoremap <M-W> :bwipeout!<CR>

" --- Configuration ---
" Edit init.vim and cd to its directory
nnoremap <leader>s :edit $MYVIMRC <bar> lcd %:p:h<CR>
" Reload init.vim configuration
nnoremap <leader>r :source $MYVIMRC<CR>
" Create snippet from selected text
vnoremap <leader>cs <Plug>(coc-convert-snippet)

" --- Tab Navigation ---
" Next / previous / close tab
nnoremap <M-J> :tabNext <CR>
nnoremap <M-K> :tabprevious <CR>
nnoremap <M-Q> :tabclose <CR>

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
nnoremap <silent> <leader><Up>    :wincmd k<CR>
nnoremap <silent> <leader><Down>  :wincmd j<CR>
nnoremap <silent> <leader><Left>  :wincmd h<CR>
nnoremap <silent> <leader><Right> :wincmd l<CR>

" --- Word Manipulation ---
" Delete current word (insert / normal mode)
inoremap <M-d> <esc>"_ciw
nnoremap <M-d> "_diw
" Backward kill word -- deletes to the start of the word (insert / normal mode)
inoremap <M-BS> <space><esc>"_cb<Del>
nnoremap <M-BS> "_db
" Forward kill word -- deletes to the end of the word (insert / normal mode)
inoremap <M-Del> <space><esc>l"_cw<BS>
nnoremap <M-Del> "_de
" Remove word after search
nnoremap _ diw
" Remove backwards to start of line
nnoremap Q d0

" --- Search ---
" Search next / previous instance of current word
nnoremap <C-F> *
nnoremap <C-D> #

" --- Clipboard-friendly Delete/Paste ---
" Delete without yanking (normal / visual)
nnoremap <leader>d "_d
vnoremap <leader>d "_d
" Paste without yanking
vnoremap <leader>p "_dP

" --- Neo-tree ---
nnoremap <silent> <C-A> :Neotree toggle<CR>
nnoremap <silent> <C-G> :Neotree reveal<CR>

" --- Commentary ---
nnoremap <space>/ :Commentary<CR>
vnoremap <space>/ :Commentary<CR>

" --- Documentation Generator (Doge) ---
nmap <silent> <leader>dg <Plug>(doge-generate)

" --- LaTeX ---
nnoremap <F2> :set spelllang=en_us<CR>:call coc#config('ltex.language', 'en-US')<CR>
nnoremap <F3> :set spelllang=es_es<CR>:call coc#config('ltex.language', 'es')<CR>
nnoremap <leader>c <Plug>(vimtex-compile)
nnoremap <leader>v :VimtexView<CR>

" --- Telescope ---
nnoremap <leader>f <cmd>Telescope find_files<cr>
nnoremap <leader>g <cmd>Telescope live_grep<cr>

" --- Clipboard ---
nnoremap <leader>cp :let @+=expand('%:p')<CR>

" --- vim-fugitive ---
nnoremap <silent> <leader>G :Git<CR>

" --- gitsigns.nvim ---
nnoremap <silent> <leader>hp :Gitsigns preview_hunk<CR>
nnoremap <silent> <leader>rh :Gitsigns reset_hunk<CR>
nnoremap <silent> ]c :Gitsigns next_hunk<CR>
nnoremap <silent> [c :Gitsigns prev_hunk<CR>

" --- todo-comments.nvim ---
nnoremap <silent> ]t <cmd>lua require('todo-comments').jump_next()<CR>
nnoremap <silent> [t <cmd>lua require('todo-comments').jump_prev()<CR>
nnoremap <silent> <leader>tt <cmd>TodoTelescope<CR>
nnoremap <silent> <leader>tf <cmd>TodoTelescope cwd=%:p:h<CR>
nnoremap <silent> <leader>tq <cmd>TodoQuickFix<CR>
nnoremap <silent> <leader>tl <cmd>TodoLocList<CR>
