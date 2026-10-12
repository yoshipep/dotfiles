-- Entry point: bootstrap lazy.nvim, load the plugins (lua/plugin_specs.lua), then the rest
-- of the config (base.vim). lazy-lock.json records the commit of every plugin.

vim.g.mapleader = ' ' -- before lazy loads any plugin

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
    local out = vim.fn.system({
        'git', 'clone', '--filter=blob:none', '--branch=stable',
        'https://github.com/folke/lazy.nvim.git', lazypath,
    })
    if vim.v.shell_error ~= 0 then
        error('Failed to clone lazy.nvim:\n' .. out)
    end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup(require('plugin_specs'), {
    rocks = { enabled = false },
    checker = { enabled = false },
    change_detection = { notify = false },
    -- lazy resets the runtimepath; nvim-treesitter (main) installs parsers and queries here
    performance = { rtp = { paths = { vim.fn.stdpath('data') .. '/site' } } },
})

vim.cmd.source(vim.fn.stdpath('config') .. '/base.vim')
