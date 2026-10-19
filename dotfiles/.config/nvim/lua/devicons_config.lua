-- nvim-web-devicons

local devicons = require('nvim-web-devicons')
devicons.setup({
  default = true,  -- Enable default icons
})
-- Shell & diff have no brand color in devicons; recolor them while keeping
-- each one's existing glyph (don't hardcode the glyph).
local icons = devicons.get_icons()
local function tint(key, color)
  local e = icons[key]
  if e then
    devicons.set_icon({ [key] = { icon = e.icon, color = color, name = e.name } })
  end
end
tint('sh', '#89e051')
tint('bash', '#89e051')
tint('zsh', '#89e051')
tint('diff', '#f1502f')
