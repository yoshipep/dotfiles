-- Plugin list. Everything tracks HEAD unless pinned here; lazy-lock.json holds the exact
-- commits (:Lazy restore returns to them, :Lazy update moves them).

return {
    -- Themes
    'pR0Ps/molokai-dark',
    { 'catppuccin/nvim', name = 'catppuccin' },
    'rebelot/kanagawa.nvim',
    'navarasu/onedark.nvim',
    'Mofiqul/vscode.nvim',
    { 'Dracula/vim', name = 'dracula' },
    'tiagovla/tokyodark.nvim',
    'ellisonleao/gruvbox.nvim',
    'sainnhe/sonokai',
    'sainnhe/everforest',

    -- LSP & completion
    'neovim/nvim-lspconfig',
    { 'saghen/blink.cmp', version = '1.*' }, -- v2 is in development; v1 ships the prebuilt binary
    { 'L3MON4D3/LuaSnip', version = '2.*' },

    -- Syntax & language support
    { 'nvim-treesitter/nvim-treesitter', branch = 'main', lazy = false, build = ':TSUpdate' },
    {
        'lervag/vimtex',
        init = function() -- vimtex reads these when it loads
            vim.g.vimtex_view_general_viewer = 'evince'
            vim.g.vimtex_compiler_method = 'latexmk'
        end,
    },
    'drinkataco/vim-md-toc',
    'OXY2DEV/markview.nvim',
    'jakewvincent/mkdnflow.nvim',
    { 'iamcco/markdown-preview.nvim', build = 'cd app && npx --yes yarn install' },

    -- Code tools
    'Raimondi/delimitMate',
    'ntpeters/vim-better-whitespace',
    'tpope/vim-commentary',
    'sbdchd/neoformat',
    { 'kkoomen/vim-doge', build = ':call doge#install()' },
    { 'stsewd/isort.nvim', build = ':UpdateRemotePlugins' },
    'folke/todo-comments.nvim',

    -- Navigation & search
    { 'junegunn/fzf', build = './install --bin' },
    'junegunn/fzf.vim',
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope.nvim', branch = 'master' },
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    'MunifTanjim/nui.nvim',
    { 'nvim-neo-tree/neo-tree.nvim', branch = 'v3.x' },

    -- Git
    'tpope/vim-fugitive',
    'tpope/vim-obsession',
    'lewis6991/gitsigns.nvim',

    -- UI
    'nvim-tree/nvim-web-devicons',
    {
        'vim-airline/vim-airline',
        init = function() -- airline reads its g:airline* settings when it loads
            vim.cmd.source(vim.fn.stdpath('config') .. '/plugins.conf/vim-airline.vim')
        end,
    },
    '0xferrous/ansi.nvim',
}
