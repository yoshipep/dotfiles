local M = {}

local function configure(direction)
  require('markview').setup({
    preview = {
      enable = false,
      splitview_winopts = { split = direction },
    },
  })
end

configure("right")

function M.vsplit()
  configure("right")
  vim.cmd("Markview splitToggle")
end

function M.hsplit()
  configure("above")
  vim.cmd("Markview splitToggle")
end

return M
