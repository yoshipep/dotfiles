-- Completion (blink.cmp) and snippets (LuaSnip). Only enabled for the filetypes
-- whose LSP already runs natively; coc still completes everything else.
-- Extend native_fts as languages move off coc.

local native_fts = {}
for _, ft in ipairs({
    'c', 'cpp', 'objc', 'objcpp', 'cuda',
    'python', 'sh', 'bash', 'asm', 'vmasm',
}) do
    native_fts[ft] = true
end

local function after_word()
    local col = vim.fn.col('.') - 1
    return col > 0 and not vim.fn.getline('.'):sub(col, col):match('%s')
end

require('blink.cmp').setup({
    enabled = function() return native_fts[vim.bo.filetype] == true end,
    keymap = {
        preset = 'default',
        -- Same feel as the coc mappings: Tab confirms / jumps / indents / triggers
        ['<Tab>'] = {
            'select_and_accept',
            'snippet_forward',
            function(cmp) if after_word() then return cmp.show() end end,
            'fallback',
        },
        ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<C-q>'] = { 'cancel' },
    },
    completion = {
        accept = { auto_brackets = { enabled = false } },
        menu = { border = 'single' },
        documentation = { auto_show = true, window = { border = 'single' } },
    },
    signature = { enabled = true, window = { border = 'single' } },
    snippets = { preset = 'luasnip' },
    sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
})

local ls = require('luasnip')
ls.filetype_extend('cpp', { 'c' })
ls.filetype_extend('bash', { 'sh' })
ls.filetype_extend('vmasm', { 'asm' })

-- snipmate-format files, one per filetype
require('luasnip.loaders.from_snipmate').lazy_load({
    paths = { vim.fn.stdpath('config') .. '/snippets' },
})

-- Needs the file name, so it can't be a plain snipmate snippet
local function guard()
    return (vim.fn.expand('%:t:r'):upper():gsub('%.', '_')) .. '_H_'
end

ls.add_snippets('c', {
    ls.snippet({ trig = 'guard', dscr = 'Generate ifdef guards' }, {
        ls.text_node('#ifndef '), ls.function_node(guard),
        ls.text_node({ '', '#define ' }), ls.function_node(guard),
        ls.text_node({ '', '' }), ls.insert_node(0),
        ls.text_node({ '', '#endif // ' }), ls.function_node(guard),
    }),
})
