return {
  views = {
    finder = {
      win                 = {
        kind = "float",
      },
      mappings            = {
        ["<C-b>"] = "CloseView",
      },
      follow_current_file = true,
    }
  },
  integrations = {
    icon = "nvim_web_devicons",
  },
}
