-- Treesitter (main branch)

require('nvim-treesitter').install({
  "c", "cpp", "python", "bash", "lua", "vim", "vimdoc",
  "markdown", "markdown_inline", "latex", "rust",
  "json", "yaml", "toml", "html", "css", "javascript",
  "make", "cmake", "dockerfile", "gitignore", "gitcommit", "diff", "regex"
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = {
    "c", "cpp", "python", "bash", "sh", "lua", "vim", "help",
    "markdown", "rust", "json", "yaml", "toml",
    "html", "css", "javascript", "make", "cmake", "dockerfile"
  },
  callback = function()
    pcall(vim.treesitter.start)
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- Highlight only (no indent queries). tex is left to VimTeX's own syntax.
vim.api.nvim_create_autocmd('FileType', {
  pattern = { "gitignore", "gitcommit", "diff" },
  callback = function() pcall(vim.treesitter.start) end,
})
