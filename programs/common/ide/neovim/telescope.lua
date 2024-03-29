-- ------------------------------------------------------------------------------------------------------------------------------
-- Search Engine
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {{
  'nvim-telescope/telescope.nvim',
  tag = '0.1.5',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'fdschmidt93/telescope-egrepify.nvim',
    {
      'AckslD/nvim-neoclip.lua',
      dependencies = {
        {'kkharji/sqlite.lua', module = 'sqlite'},
      },
      config = function()
        require('neoclip').setup({
          history = 10000,
          enable_persistent_history = true,
          keys = {
            telescope = {
              i = {
                paste = '<cr>',
                paste_behind = '<c-i>',
                replay = '<c-q>',  -- replay a macro
                delete = '<c-d>',  -- delete an entry
                edit = '<c-e>',  -- edit an entry
                custom = {},
              },
              n = {
                paste = 'p',
                --- It is possible to map to more than one key.
                -- paste = { 'p', '<c-p>' },
                paste_behind = 'P',
                replay = 'q',
                delete = 'd',
                edit = 'e',
                custom = {},
              },
            },
          },
        })
      end,
    },
    'debugloop/telescope-undo.nvim',
    'ghassan0/telescope-glyph.nvim',
    'xiyaowong/telescope-emoji.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make'
    },
  },
  config = function()
    require('telescope').setup({
      defaults = {
        mappings = {
          i = {
            ['<c-j>'] = 'move_selection_next',
            ['<c-k>'] = 'move_selection_previous',
            ['<esc>'] = 'close',
          },
        },
        file_ignore_patterns = {'%.git/'},
      },
      extensions = {
        fzf = {
          fuzzy = true,                    -- false will only do exact matching
          override_generic_sorter = true,  -- override the generic sorter
          override_file_sorter = true,     -- override the file sorter
          case_mode = 'smart_case',        -- or 'ignore_case' or 'respect_case'
                                           -- the default case_mode is 'smart_case'
        },
        undo = {
          -- telescope-undo.nvim config, see below
          layout_config = {
            preview_width = 0.7,
          },
          mappings = {
            i = {
              ['<cr>'] = require('telescope-undo.actions').restore,
            },
            n = {
              ['y'] = require('telescope-undo.actions').yank_additions,
              ['Y'] = require('telescope-undo.actions').yank_deletions,
              ['<cr>'] = require('telescope-undo.actions').restore,
            },
          },
        },
      }
    })
    require('telescope').load_extension('egrepify')
    require('telescope').load_extension('fzf')
    require('telescope').load_extension('undo')
    require('telescope').load_extension('emoji')
    require('telescope').load_extension('glyph')
    require('telescope').load_extension('neoclip')

    keysRegisterSearch()
  end,
}})
