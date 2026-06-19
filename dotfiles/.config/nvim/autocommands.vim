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
function! s:MarkdownSetup() abort
    if get(b:, 'markdown_setup_done', 0) | return | endif
    setlocal spell
    nnoremap <buffer> <silent> <leader>v :lua require('markview_config').vsplit()<CR>
    nnoremap <buffer> <silent> <leader>h :lua require('markview_config').hsplit()<CR>
    let b:markdown_setup_done = 1
endfunction
augroup MarkdownSetup
    autocmd!
    autocmd FileType markdown call s:MarkdownSetup()
    autocmd VimEnter * if &filetype ==# 'markdown' | call s:MarkdownSetup() | endif
augroup END

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

" Format on save
augroup FormatOnSave
  autocmd!
  autocmd BufWritePre *.tex silent! Neoformat
  autocmd BufWritePre * if &filetype !=# 'tex' | silent! call CocAction('format') | endif
augroup END
