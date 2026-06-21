local M = {}

local function configure(direction)
  -- Force every built-in reference-definition site rule to use our purple,
  -- keeping each site's default icon (markview deep-merges these by pattern key).
  local ref_icon = "\239\133\140 "
  local ref_defs = {
    enable = true,
    default = { icon = ref_icon, hl = "MarkviewRefPurple" },
  }
  local ref_patterns = {
    "github%.com/[%a%d%-%_%.]+%/?$",
    "github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/?$",
    "github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+/tree/[%a%d%-%_%.]+%/?$",
    "github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+/commits/[%a%d%-%_%.]+%/?$",
    "github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/releases$",
    "github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/tags$",
    "github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/issues$",
    "github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/pulls$",
    "github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/wiki$",
    "developer%.mozilla%.org",
    "w3schools%.com",
    "stackoverflow%.com",
    "reddit%.com",
    "github%.com",
    "gitlab%.com",
    "dev%.to",
    "codepen%.io",
    "replit%.com",
    "jsfiddle%.net",
    "npmjs%.com",
    "pypi%.org",
    "mvnrepository%.com",
    "medium%.com",
    "linkedin%.com",
    "news%.ycombinator%.com",
  }
  for _, pat in ipairs(ref_patterns) do
    ref_defs[pat] = { icon = ref_icon, hl = "MarkviewRefPurple" }
  end

  -- Hyperlinks: same chain icon + teal/underline for every URL (no per-site icons).
  local link_icon = "\243\176\140\183 "
  local link_defs = {
    enable = true,
    default = { icon = link_icon, hl = "MarkviewLinkTeal" },
  }
  for _, pat in ipairs(ref_patterns) do
    link_defs[pat] = { icon = link_icon, hl = "MarkviewLinkTeal" }
  end

  -- Emails: one icon (the default envelope) + one amber color for all providers.
  local email_icon = "\239\144\149 "
  local email_defs = {
    enable = true,
    default = { icon = email_icon, hl = "MarkviewEmail" },
  }
  for _, pat in ipairs({ "%@gmail%.com$", "%@outlook%.com$", "%@yahoo%.com$", "%@icloud%.com$" }) do
    email_defs[pat] = { icon = email_icon, hl = "MarkviewEmail" }
  end

  -- Images: default icon for everything, green; PDF keeps its own icon.
  local image_icon = "\243\176\165\182 "
  local image_defs = {
    enable = true,
    default = { icon = image_icon, hl = "MarkviewImage" },
    ["%.pdf$"] = { hl = "MarkviewImage" },
  }
  for _, pat in ipairs({ "%.svg$", "%.png$", "%.jpg$", "%.gif$" }) do
    image_defs[pat] = { icon = image_icon, hl = "MarkviewImage" }
  end

  require('markview').setup({
    preview = {
      enable = false,
      icon_provider = "devicons",
      splitview_winopts = { split = direction },
    },
    markdown = {
      block_quotes = {
        enable = true,
        default = { border = "┃", border_hl = "MarkviewListBlue" },
        ["NOTE"]      = { border = "┃", border_hl = "MarkviewListBlue", preview_hl = "MarkviewListBlue" },
        ["TIP"]       = { border = "┃", border_hl = "MarkviewListBlue", preview_hl = "MarkviewListBlue" },
        ["IMPORTANT"] = { border = "┃", border_hl = "MarkviewListBlue", preview_hl = "MarkviewListBlue" },
        ["WARNING"]   = { border = "┃", border_hl = "MarkviewListBlue", preview_hl = "MarkviewListBlue" },
        ["CAUTION"]   = { border = "┃", border_hl = "MarkviewListBlue", preview_hl = "MarkviewListBlue" },
      },
      code_blocks = {
        enable = true,
        style = "block",
        label_direction = "right",
        sign = false,
        pad_amount = 4,
        ["diff"] = {
          block_hl = function(_, line)
            if line:match("^%+") then
              return "MarkviewDiffAdd"
            elseif line:match("^%-") then
              return "MarkviewDiffDelete"
            else
              return "MarkviewDiffContext"
            end
          end,
          pad_hl = "MarkviewCode",
        },
      },
      headings = {
        enable = true,
        heading_1 = { style = "icon", sign = "", hl = "MarkviewH1" },
        heading_2 = { style = "icon", sign = "", hl = "MarkviewH2" },
        heading_3 = { style = "icon", sign = "", hl = "MarkviewH3" },
        heading_4 = { style = "icon", sign = "", hl = "MarkviewH4" },
        heading_5 = { style = "icon", sign = "", hl = "MarkviewH5" },
        heading_6 = { style = "icon", sign = "", hl = "MarkviewH6" },
        setext_1 = { style = "decorated", hl = "MarkviewH1", sign = "", icon = "\238\170\171 " },
        setext_2 = { style = "decorated", hl = "MarkviewH2", sign = "", icon = "\238\170\170 " },
        shift_width = 0,
      },
      metadata_minus = {
        enable = true,
        hl = "MarkviewMetaTransparent",
        border_hl = "MarkviewListBlue",
        border_top = "─",
        border_bottom = "─",
      },
      metadata_plus = {
        enable = true,
        hl = "MarkviewMetaTransparent",
        border_hl = "MarkviewListBlue",
        border_top = "─",
        border_bottom = "─",
      },
      list_items = {
        enable = true,
        wrap = true,
        marker_minus = { text = "•", hl = "MarkviewListBlue" },
        marker_plus = { text = "◦", hl = "MarkviewListBlue" },
        marker_star = { text = "▪", hl = "MarkviewListBlue" },
        marker_dot = { hl = "MarkviewListBlue" },
        marker_parenthesis = { hl = "MarkviewListBlue" },
      },
      horizontal_rules = {
        enable = true,
        parts = {
          {
            type = "repeating",
            direction = "left",
            repeat_amount = function(buffer)
              local utils = require("markview.utils")
              local window = utils.buf_getwin(buffer)
              local width = vim.api.nvim_win_get_width(window)
              local textoff = vim.fn.getwininfo(window)[1].textoff
              return math.floor((width - textoff - 3) / 2)
            end,
            text = "─",
            hl = {
              "MarkviewBlueGradient1", "MarkviewBlueGradient2", "MarkviewBlueGradient3",
              "MarkviewBlueGradient4", "MarkviewBlueGradient5", "MarkviewBlueGradient6",
              "MarkviewBlueGradient7", "MarkviewBlueGradient8", "MarkviewBlueGradient9",
            },
          },
          {
            type = "text",
            text = " \238\170\170 ",
            hl = "MarkviewBlueGradient9",
          },
          {
            type = "repeating",
            direction = "right",
            repeat_amount = function(buffer)
              local utils = require("markview.utils")
              local window = utils.buf_getwin(buffer)
              local width = vim.api.nvim_win_get_width(window)
              local textoff = vim.fn.getwininfo(window)[1].textoff
              return math.ceil((width - textoff - 3) / 2)
            end,
            text = "─",
            hl = {
              "MarkviewBlueGradient1", "MarkviewBlueGradient2", "MarkviewBlueGradient3",
              "MarkviewBlueGradient4", "MarkviewBlueGradient5", "MarkviewBlueGradient6",
              "MarkviewBlueGradient7", "MarkviewBlueGradient8", "MarkviewBlueGradient9",
            },
          },
        },
      },
      reference_definitions = ref_defs,
      tables = {
        enable = true,
        strict = false,
        block_decorator = true,
        use_virt_lines = false,
        parts = {
          top = { "┌", "─", "┐", "┬" },
          header = { "│", "│", "│" },
          separator = { "├", "─", "┤", "┼" },
          row = { "│", "│", "│" },
          bottom = { "└", "─", "┘", "┴" },
          overlap = { "├", "─", "┤", "┼" },
          align_left = "╼",
          align_right = "╾",
          align_center = { "╴", "╶" },
        },
        hl = {
          top = { "MarkviewListBlue", "MarkviewListBlue", "MarkviewListBlue", "MarkviewListBlue" },
          header = { "MarkviewListBlue", "MarkviewListBlue", "MarkviewListBlue" },
          separator = { "MarkviewListBlue", "MarkviewListBlue", "MarkviewListBlue", "MarkviewListBlue" },
          row = { "MarkviewListBlue", "MarkviewListBlue", "MarkviewListBlue" },
          bottom = { "MarkviewListBlue", "MarkviewListBlue", "MarkviewListBlue", "MarkviewListBlue" },
          overlap = { "MarkviewListBlue", "MarkviewListBlue", "MarkviewListBlue", "MarkviewListBlue" },
          align_left = "MarkviewListBlue",
          align_right = "MarkviewListBlue",
          align_center = { "MarkviewListBlue", "MarkviewListBlue" },
        },
      },
    },
    markdown_inline = {
      hyperlinks = link_defs,
      uri_autolinks = link_defs,
      checkboxes = {
        enable = true,
        checked = { scope_hl = "MarkviewCheckboxCheckedScope" },
      },
      emails = email_defs,
      images = image_defs,
      footnotes = {
        enable = true,
        default = { icon = "", hl = "MarkviewRefPurple" },
        ["^%d+$"] = { icon = "", hl = "MarkviewRefPurple" },
      },
      highlights = {
        enable = true,
        default = { padding_left = "", padding_right = "", hl = "MarkviewHighlightMark" },
      },
      tags = {
        enable = true,
        default = { padding_left = "", padding_right = "", hl = "MarkviewTag" },
      },
      inline_codes = {
        enable = true,
        hl = "MarkviewInlineCode",
        padding_left = "",
        padding_right = "",
      },
    },
    yaml = {
      properties = {
        enable = true,
        default = { use_types = true, hl = "MarkviewListBlue" },
        data_types = {
          ["text"]        = { hl = "MarkviewListBlue" },
          ["list"]        = { hl = "MarkviewListBlue" },
          ["number"]      = { hl = "MarkviewListBlue" },
          ["checkbox"]    = { hl = "MarkviewListBlue" },
          ["date"]        = { hl = "MarkviewListBlue" },
          ["date_&_time"] = { hl = "MarkviewListBlue" },
        },
      },
    },
  })

  -- Green/red foreground for diff lines, keeping the code block background.
  local code_bg = vim.api.nvim_get_hl(0, { name = "MarkviewCode" }).bg
  vim.api.nvim_set_hl(0, "MarkviewDiffAdd", { fg = "#50fa7b", bg = code_bg })
  vim.api.nvim_set_hl(0, "MarkviewDiffDelete", { fg = "#ff5555", bg = code_bg })
  vim.api.nvim_set_hl(0, "MarkviewDiffContext", { fg = "#f8f8f2", bg = code_bg })

  -- Monochrome graded palette per heading level (demo): one hue, dimming with depth.
  vim.api.nvim_set_hl(0, "MarkviewH1", { fg = "#82aaff", bold = true })
  vim.api.nvim_set_hl(0, "MarkviewH2", { fg = "#6f99ee", bold = true })
  vim.api.nvim_set_hl(0, "MarkviewH3", { fg = "#5d88dc", bold = true })
  vim.api.nvim_set_hl(0, "MarkviewH4", { fg = "#4d77c7", bold = true })
  vim.api.nvim_set_hl(0, "MarkviewH5", { fg = "#3f66ad", bold = true })
  vim.api.nvim_set_hl(0, "MarkviewH6", { fg = "#33548f", bold = true })

  -- Blue gradient for horizontal rules (dark -> bright).
  local blue_gradient = {
    "#1a2a4a", "#243a63", "#2e4a7c", "#385a95", "#426aae",
    "#4d7ac7", "#5d8ad8", "#6f9aee", "#82aaff",
  }
  for i, color in ipairs(blue_gradient) do
    vim.api.nvim_set_hl(0, "MarkviewBlueGradient" .. i, { fg = color })
  end

  -- Blue list markers.
  vim.api.nvim_set_hl(0, "MarkviewListBlue", { fg = "#82aaff" })

  -- Transparent background for metadata blocks.
  vim.api.nvim_set_hl(0, "MarkviewMetaTransparent", { bg = "none" })

  -- Distinct purple for default reference definitions (mid, not neon).
  vim.api.nvim_set_hl(0, "MarkviewRefPurple", { fg = "#c060f5" })

  -- Teal + underline for hyperlinks (link usage), distinct from blue/purple.
  vim.api.nvim_set_hl(0, "MarkviewLinkTeal", { fg = "#2bbac5", underline = true })

  -- Bold + italic both render (0xProto ships Regular/Bold/Italic faces).
  vim.api.nvim_set_hl(0, "@markup.strong", { bold = true })
  vim.api.nvim_set_hl(0, "@markup.italic", { italic = true })

  -- Emails: soft pink, distinct from teal links and purple references.
  vim.api.nvim_set_hl(0, "MarkviewEmail", { fg = "#ff79c6" })

  -- Images: punchy green, distinct from the other link-type accents.
  vim.api.nvim_set_hl(0, "MarkviewImage", { fg = "#4ade80" })

  -- Inline code: amber text, no background.
  vim.api.nvim_set_hl(0, "MarkviewInlineCode", { fg = "#e0af68" })

  -- Highlighted (==text==): vivid yellow marker on a more present tint.
  vim.api.nvim_set_hl(0, "MarkviewHighlightMark", { fg = "#ffd633", bg = "#403613" })

  -- Tags (#tag): punchy red (mid).
  vim.api.nvim_set_hl(0, "MarkviewTag", { fg = "#ff5555" })


  -- Checkboxes in the blue palette (glyph shapes already distinguish states).
  vim.api.nvim_set_hl(0, "MarkviewCheckboxChecked", { fg = "#82aaff" })
  vim.api.nvim_set_hl(0, "MarkviewCheckboxUnchecked", { fg = "#82aaff" })
  vim.api.nvim_set_hl(0, "MarkviewCheckboxPending", { fg = "#82aaff" })
  vim.api.nvim_set_hl(0, "MarkviewCheckboxProgress", { fg = "#82aaff" })
  vim.api.nvim_set_hl(0, "MarkviewCheckboxCancelled", { fg = "#82aaff" })
  vim.api.nvim_set_hl(0, "MarkviewCheckboxStriked", { fg = "#5d88dc", strikethrough = true })
  -- Completed items: harder, more saturated blue (bold won't render — no bold font face).
  vim.api.nvim_set_hl(0, "MarkviewCheckboxCheckedScope", { fg = "#2f7dff", bold = true })
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
