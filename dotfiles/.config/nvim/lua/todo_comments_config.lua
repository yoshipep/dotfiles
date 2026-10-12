-- todo-comments.nvim
-- Colors are hardcoded (hex first, so they win over the theme's Diagnostic groups)
-- to match the gitsigns palette across the themes in ~/.vim_theme; the plugin
-- re-applies them on ColorScheme itself. Signs sit below gitsigns' priority 6 so
-- hunk markers keep the sign column.

require("todo-comments").setup({
  signs = true,
  sign_priority = 5,
  keywords = {
    FIX  = { icon = ' ', color = 'error',   alt = { 'FIXME', 'BUG', 'ISSUE' } },
    TODO = { icon = ' ', color = 'info',    },
    HACK = { icon = ' ', color = 'warning', alt = { 'XXX', 'KLUDGE' } },
    WARN = { icon = ' ', color = 'warning', alt = { 'WARNING', 'DEPRECATED' } },
    PERF = { icon = ' ', color = 'perf',    alt = { 'OPTIM', 'OPTIMIZE', 'PERFORMANCE' } },
    NOTE = { icon = ' ', color = 'hint',    alt = { 'INFO' } },
    TEST = { icon = '⏲ ', color = 'test',    alt = { 'TESTING', 'PASSED', 'FAILED' } },
  },
  gui_style = {
    fg = 'NONE',
    bg = 'BOLD',
  },
  highlight = {
    multiline = true,
    multiline_pattern = '^.',
    multiline_context = 10,
    before = '',
    keyword = 'wide',   -- colored block over the keyword and its sign
    after = 'fg',       -- comment body in the keyword's color
    pattern = [[.*<(KEYWORDS)\s*:]],
    comments_only = true,
    max_line_len = 400,
    exclude = {},
  },
  colors = {
    error   = { '#ff5f5f' },
    warning = { '#ff8700' },
    info    = { '#5f87ff' },
    hint    = { '#00d75f' },
    perf    = { '#af87ff' },
    test    = { '#00afaf' },
    default = { '#d75f87' },
  },
  search = {
    command = 'rg',
    args = {
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
    },
    pattern = [[\b(KEYWORDS):]],
  },
})
