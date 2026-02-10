" https://github.com/neoclide/coc.nvim
" https://github.com/neoclide/coc.nvim/wiki/Completion-with-sources

" Helper function to check if cursor is after whitespace
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" CoC snippet configuration
let g:coc_snippet_next = '<tab>'
let g:coc_snippet_prev = '<s-tab>'

" Enhanced TAB completion with snippet support
" - Confirms selection if popup menu is visible
" - Expands/jumps snippets if available
" - Falls back to normal tab behavior
" - Triggers completion if not at whitespace
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

" SHIFT-TAB to navigate backwards in completion menu
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Use <c-space> to trigger completion
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Use <CR> to confirm completion
inoremap <expr> <cr> coc#pum#visible() ? coc#_select_confirm() : "\<CR>"

" Use <C-Q> to cancel completion menu
inoremap <expr> <C-Q> coc#pum#visible() ? coc#pum#cancel() : ""

" Use `[c` and `]c` to navigate diagnostics
nmap <silent> <leader>e <Plug>(coc-diagnostic-prev)
nmap <silent> <leader>E <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word, auto-save all modified buffers and close
" any newly opened ones afterward
function! s:rename_and_save() abort
  let l:bufs_before = getbufinfo({'buflisted': 1})
  let l:known = {}
  for b in l:bufs_before
    let l:known[b.bufnr] = 1
  endfor
  call CocActionAsync('rename', '', {err, res ->
    \ execute('silent! wa') + s:close_new_buffers(l:known)
    \ })
endfunction

function! s:close_new_buffers(known) abort
  let l:cur = bufnr('%')
  for b in getbufinfo({'buflisted': 1})
    if !has_key(a:known, b.bufnr) && b.bufnr != l:cur
      execute 'silent! bdelete' b.bufnr
    endif
  endfor
endfunction

nmap <silent> <leader>rn :call <SID>rename_and_save()<CR>

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <leader>qf  <Plug>(coc-fix-current)

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add status line support, for integration with other plugin, checkout `:h coc-status`
" Note: Disabled because vim-airline handles statusline and includes CoC integration
" set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Using CocList
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>
