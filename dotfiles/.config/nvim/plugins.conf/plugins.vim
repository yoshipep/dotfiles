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
  close_if_last_window = true,
  popup_border_style = "rounded",
  enable_git_status = true,
  enable_diagnostics = true,
  filesystem = {
    follow_current_file = {
      enabled = true,
    },
    hijack_netrw_behavior = "open_default",
    use_libuv_file_watcher = true,
  },
  window = {
    position = "left",
    width = 30,
    mappings = {
      ["<space>"] = "none",
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

  sync_install = false,
  auto_install = true,

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },

  indent = {
    enable = true
  },
}
EOF

" --- ansi.vim ---
lua << EOF
require('ansi'). setup({
  auto_enable = true,
  filetypes = { 'log', 'ansi', 'term', 'txt' }
})
EOF

" --- gitsigns.nvim ---
lua << EOF
require("gitsigns").setup({
  on_attach = function(bufnr)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    -- Do not attach to git special buffers (COMMIT_EDITMSG, MERGE_MSG, etc.)
    if bufname:match('%.git/') then return false end
  end,
  signs = {
    add          = { text = '+' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged = {
    add          = { text = '+' },
    change       = { text = '┃' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signs_staged_enable = true,
  signcolumn = true,
  watch_gitdir = {
    follow_files = true
  },
  auto_attach = true,
  sign_priority = 6,
  update_debounce = 100,
  status_formatter = nil,
  max_file_length = 40000, -- Disable if file is longer than this (in lines)
  preview_config = {
    -- Options passed to nvim_open_win
    border = 'single',
    relative = 'cursor',
    row = 0,
    col = 1
  }
})

local function set_gitsigns_colors()
    -- unstaged
  vim.api.nvim_set_hl(0, "GitSignsAdd",    { fg = "#00d75f", bold = true })
  vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#ff5f5f", bold = true })
  vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#5f87ff", bold = true })
  -- staged (darker / dimmer variants)
  vim.api.nvim_set_hl(0, "GitSignsStagedAdd",    { fg = "#00af4f" })
  vim.api.nvim_set_hl(0, "GitSignsStagedDelete", { fg = "#d75f5f" })
  vim.api.nvim_set_hl(0, "GitSignsStagedChange", { fg = "#4f6fd7" })
end

set_gitsigns_colors()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_gitsigns_colors })
EOF
