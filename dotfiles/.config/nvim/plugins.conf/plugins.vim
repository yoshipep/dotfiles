" ============================================================================
" PLUGIN CONFIGURATIONS
" ============================================================================

" --- Neoformat ---
let g:neoformat_clangformat = {
        \ 'exe': 'clang-format',
        \ 'args': ['-style=file', '-fallback-style=LLVM'],
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
" Neovim's Python host lives in a WORKON_HOME venv (`workon neovim`) so pynvim + the
" isort library stay current regardless of distro; apt's python3-pynvim lags a
" source-built nvim. The installer creates it.
let g:python3_host_prog = expand('~/.virtualenvs/neovim/bin/python3')
let g:isort_command = 'isort'

" --- markdown-preview.nvim ---
" One browser tab that follows the active markdown buffer and holds the last
" markdown (stays open) when the active buffer is not markdown.
let g:mkdp_combine_preview = 1
let g:mkdp_combine_preview_auto_refresh = 1
let g:mkdp_auto_close = 0
let g:mkdp_auto_start = 0
nmap <leader>mp <Plug>MarkdownPreviewToggle

" --- Sphinx live preview (~/scripts/sphinx-serve.sh) ---
" Bottom terminal running sphinx-autobuild for the project in nvim's cwd; serves,
" live-reloads, opens the browser. Ctrl-C in the pane to stop. Height is re-asserted
" on VimResized so collapsing/zooming the tmux pane keeps it at 15 lines.
command! SphinxServe call <SID>SphinxServe()

function! s:SphinxServe() abort
  botright 15split
  setlocal winfixheight
  terminal sphinx-serve.sh
  let b:sphinx_serve = 1
endfunction

function! s:SphinxFixHeight() abort
  for w in range(1, winnr('$'))
    if getbufvar(winbufnr(w), 'sphinx_serve', 0)
      call nvim_win_set_height(win_getid(w), 15)
    endif
  endfor
endfunction

augroup SphinxServeHeight
  autocmd!
  autocmd VimResized * call <SID>SphinxFixHeight()
augroup END

nnoremap <leader>sp :SphinxServe<CR>

" --- C/C++ ---
" .h is C, not C++ (filetype detection)
let g:c_syntax_for_h = 1
