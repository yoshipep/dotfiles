" ============================================================================
" PLUGIN CONFIGURATIONS
" ============================================================================

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
