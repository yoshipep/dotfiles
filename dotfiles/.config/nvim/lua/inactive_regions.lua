-- Lightweight secondary clangd client that only handles
-- textDocument/inactiveRegions notifications.
-- The primary LSP (CoC) handles everything else.

local ns = vim.api.nvim_create_namespace('clangd_inactive_regions')

vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'c', 'cpp' },
    callback = function(args)
        local root = vim.fs.root(args.buf, { 'compile_commands.json', 'compile_flags.txt', '.git' })
        if not root then
            return
        end

        vim.lsp.start({
            name = 'clangd-inactive',
            cmd = { 'clangd', '--header-insertion=never', '--log=error' },
            root_dir = root,
            capabilities = {
                textDocument = {
                    inactiveRegionsCapabilities = {
                        inactiveRegions = true,
                    },
                },
            },
            handlers = {
                ['textDocument/inactiveRegions'] = function(err, result)
                    if err or not result then
                        return
                    end

                    local uri = result.textDocument.uri
                    local bufnr = vim.uri_to_bufnr(uri)
                    if not vim.api.nvim_buf_is_valid(bufnr) then
                        return
                    end

                    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
                    for _, region in ipairs(result.regions) do
                        for line = region.start.line, region['end'].line do
                            pcall(vim.api.nvim_buf_add_highlight, bufnr, ns, 'CocInactiveRegion', line, 0, -1)
                        end
                    end
                end,
                -- Suppress diagnostics from this client (CoC handles them)
                ['textDocument/publishDiagnostics'] = function() end,
            },
            on_init = function(client)
                -- Disable all capabilities so this client doesn't interfere with CoC
                local sc = client.server_capabilities
                sc.completionProvider = nil
                sc.hoverProvider = nil
                sc.signatureHelpProvider = nil
                sc.definitionProvider = nil
                sc.typeDefinitionProvider = nil
                sc.implementationProvider = nil
                sc.referencesProvider = nil
                sc.documentHighlightProvider = nil
                sc.documentSymbolProvider = nil
                sc.codeActionProvider = nil
                sc.documentFormattingProvider = nil
                sc.renameProvider = nil
                sc.inlayHintProvider = nil
                sc.semanticTokensProvider = nil
            end,
        })
    end,
})
