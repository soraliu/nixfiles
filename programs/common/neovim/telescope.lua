
-- ------------------------------------------------------------------------------------------------------------------------------
-- Search Engine
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {{
  "fdschmidt93/telescope-egrepify.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
}, {
  'nvim-telescope/telescope-fzf-native.nvim',
  build = 'make'
}, {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.5',
  config = function()
    require('telescope').setup({
      defaults = {
        mappings = keysPluginTelescope(),
        file_ignore_patterns = {'%.git/'},
      },
      extensions = {
        fzf = {
          fuzzy = true,                    -- false will only do exact matching
          override_generic_sorter = true,  -- override the generic sorter
          override_file_sorter = true,     -- override the file sorter
          case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                           -- the default case_mode is "smart_case"
        }
      }
    })
    require('telescope').load_extension('egrepify')
    require('telescope').load_extension('fzf')

    keysRegisterSearch()
  end,
}})

