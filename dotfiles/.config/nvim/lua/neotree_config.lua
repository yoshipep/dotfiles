-- Neo-tree

require('neo-tree').setup({
  close_if_last_window = true,
  popup_border_style = "rounded",
  enable_git_status = true,
  enable_diagnostics = true,
  filesystem = {
    follow_current_file = {
      enabled = true,
    },
    hijack_netrw_behavior = "open_default",
    use_libuv_file_watcher = true,
  },
  window = {
    position = "left",
    width = 30,
    mappings = {
      ["<space>"] = "none",
      ["<cr>"] = "open",
      ["o"] = "open",
    },
  },
  event_handlers = {
    {
      event = "file_opened",
      handler = function(file_path)
        require("neo-tree.command").execute({ action = "close" })
      end
    },
  },
  default_component_configs = {
    indent = {
      padding = 0,
    },
  },
})
