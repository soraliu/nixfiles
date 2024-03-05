
-- ------------------------------------------------------------------------------------------------------------------------------
-- Sidebar
-- TODO :h nvim-tree-opts-diagnostics
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      -- disable netrw at the very start of your init.lua
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      -- optionally enable 24-bit colour
      vim.opt.termguicolors = true

      -- register keymaps
      local on_attach = keysRegisterTree()

      -- OR setup with some options
      require("nvim-tree").setup({
        on_attach = on_attach,
        sort = {
          sorter = "case_sensitive",
        },
        view = {
          width = 30,
          side = "right",
        },
        ui = {
          confirm = {
            default_yes = true,
          },
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = false,
        },
      })
    end
  },
})

