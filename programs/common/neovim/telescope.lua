
-- ------------------------------------------------------------------------------------------------------------------------------
-- Search Engine
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  "fdschmidt93/telescope-egrepify.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      'nvim-telescope/telescope.nvim',
      tag = '0.1.5',
      config = function()
        require('telescope').setup{
          defaults = {
            mappings = keysRegisterTelescope(),
            file_ignore_patterns = {'%.git/'},
          },
        }

        require "telescope".load_extension "egrepify"
      end,
    },
  },
})

