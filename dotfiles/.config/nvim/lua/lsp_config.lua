-- Native LSP. Languages move here from coc one group at a time; coc keeps the rest.
-- Server defaults (filetypes, root markers) come from nvim-lspconfig.

vim.lsp.config('*', {
    capabilities = require('blink.cmp').get_lsp_capabilities(),
})

-- clangd (c, cpp, ...)
local inactive_ns = vim.api.nvim_create_namespace('clangd_inactive_regions')

vim.lsp.config('clangd', {
    cmd = {
        'clangd',
        '--header-insertion=never',
        '--compile-commands-dir=build',
        '--background-index',
        '--clang-tidy',
        '--completion-style=detailed',
        '--log=error',
    },
    init_options = { fallbackFlags = { '-Wall' } },
    capabilities = {
        textDocument = { inactiveRegionsCapabilities = { inactiveRegions = true } },
    },
    handlers = {
        -- Dim #ifdef blocks that won't compile
        ['textDocument/inactiveRegions'] = function(err, result)
            if err or not result then
                return
            end
            local bufnr = vim.uri_to_bufnr(result.textDocument.uri)
            if not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end
            vim.api.nvim_buf_clear_namespace(bufnr, inactive_ns, 0, -1)
            for _, region in ipairs(result.regions) do
                pcall(vim.api.nvim_buf_set_extmark, bufnr, inactive_ns, region.start.line, 0, {
                    end_row = region['end'].line + 1,
                    end_col = 0,
                    hl_group = 'InactiveRegion',
                })
            end
        end,
    },
})
vim.lsp.enable('clangd')

vim.diagnostic.config({ severity_sort = true, float = { border = 'single' } })

-- Reference highlights (the groups coc used to define)
for _, g in ipairs({ 'LspReferenceText', 'LspReferenceRead', 'LspReferenceWrite' }) do
    vim.api.nvim_set_hl(0, g, { link = 'CursorColumn', default = true })
end

-- Rename, then write every modified buffer and close the ones the rename opened
local function rename_and_save()
    local known = {}
    for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
        known[b.bufnr] = true
    end
    local cur = vim.api.nvim_get_current_buf()
    local client = vim.lsp.get_clients({ bufnr = cur, method = 'textDocument/rename' })[1]
    if not client then
        return
    end
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

    vim.ui.input({ prompt = 'Rename to: ', default = vim.fn.expand('<cword>') }, function(name)
        if not name or name == '' then
            return
        end
        params.newName = name
        client:request('textDocument/rename', params, function(err, res)
            if err or not res then
                return
            end
            vim.lsp.util.apply_workspace_edit(res, client.offset_encoding)
            vim.cmd('silent! wa')
            for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
                if not known[b.bufnr] and b.bufnr ~= cur then
                    vim.cmd('silent! bdelete ' .. b.bufnr)
                end
            end
        end, cur)
    end)
end

-- Buffer-local, so they override the global coc mappings in coc.vim only where a
-- native client is attached.
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local buf = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local function map(mode, lhs, rhs)
            vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true })
        end
        local tb = function(fn)
            return function() require('telescope.builtin')[fn]() end
        end

        map('n', 'gd', vim.lsp.buf.definition)
        map('n', 'gy', vim.lsp.buf.type_definition)
        map('n', 'gi', vim.lsp.buf.implementation)
        map('n', 'gr', tb('lsp_references'))
        map('n', 'K', function() vim.lsp.buf.hover({ border = 'single' }) end)
        map('n', '<leader>rn', rename_and_save)

        map({ 'n', 'x' }, '<leader>a', vim.lsp.buf.code_action)
        map('n', '<leader>ac', vim.lsp.buf.code_action)
        map('n', '<leader>qf', function()
            vim.lsp.buf.code_action({
                filter = function(a) return a.isPreferred end,
                apply = true,
            })
        end)

        map('n', '<leader>[', function() vim.diagnostic.jump({ count = -1, float = true }) end)
        map('n', '<leader>]', function() vim.diagnostic.jump({ count = 1, float = true }) end)

        map('n', '<leader>la', tb('diagnostics'))
        map('n', '<leader>lo', tb('lsp_document_symbols'))
        map('n', '<leader>ls', tb('lsp_dynamic_workspace_symbols'))

        if client and client:supports_method('textDocument/documentHighlight') then
            local grp = vim.api.nvim_create_augroup('lsp_highlight_' .. buf, { clear = true })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                group = grp, buffer = buf, callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                group = grp, buffer = buf, callback = vim.lsp.buf.clear_references,
            })
        end
    end,
})
