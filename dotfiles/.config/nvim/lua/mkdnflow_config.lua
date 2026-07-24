require('mkdnflow').setup({
  modules = {
    tables = false,  -- markview renders tables; keep mkdnflow off them (and off insert <Tab>)
  },
  mappings = {
    -- coc owns insert <Tab>/<S-Tab>; belt-and-suspenders even with tables off
    MkdnTableNextCell = false,
    MkdnTablePrevCell = false,
    -- keep core vim keys in markdown buffers
    MkdnNewListItemBelowInsert = false,  -- keep o
    MkdnNewListItemAboveInsert = false,  -- keep O
    MkdnIncreaseHeading = false,         -- keep +
    MkdnDecreaseHeading = false,         -- keep -
    -- keep global leader maps in markdown buffers
    MkdnFoldSection = false,             -- keep <leader>f (Telescope find_files)
    MkdnUnfoldSection = false,           -- keep <leader>F
    MkdnCreateLinkFromClipboard = false, -- keep visual <leader>p (paste without yank)
  },
})
