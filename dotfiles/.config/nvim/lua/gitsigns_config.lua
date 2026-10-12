-- gitsigns.nvim

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
