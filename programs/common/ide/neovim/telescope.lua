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
    'nvim-telescope/telescope-symbols.nvim',
    'nvim-telescope/telescope-ui-select.nvim',
    'tsakirist/telescope-lazy.nvim',
    'nvim-telescope/telescope-file-browser.nvim',
    'benfowler/telescope-luasnip.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make'
    },
  },
  config = function()
    local fb_actions = require "telescope".extensions.file_browser.actions
    local ts_actions = require "telescope.actions"

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
        ['ui-select'] = {
          require('telescope.themes').get_dropdown {
            -- even more opts
          }
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
        lazy = {
          -- Optional theme (the extension doesn't set a default theme)
          theme = "ivy",
          -- Whether or not to show the icon in the first column
          show_icon = true,
          -- Mappings for the actions
          mappings = {
            open_in_browser = "<C-o>",
            open_in_file_browser = "<C-b>",
            open_in_find_files = "<C-l>",
            open_in_live_grep = "<C-s>",
            open_in_terminal = "<C-t>",
            open_lazy_root_find_files = "<C-r>l",
            open_lazy_root_live_grep = "<C-r>s",
          },
          -- Extra configuration options for the actions
          actions_opts = {
            open_in_browser = {
              -- Close the telescope window after the action is executed
              auto_close = false,
            },
            change_cwd_to_plugin = {
              -- Close the telescope window after the action is executed
              auto_close = false,
            },
          },
          -- Configuration that will be passed to the window that hosts the terminal
          -- For more configuration options check 'nvim_open_win()'
          terminal_opts = {
            relative = 'editor',
            style = 'minimal',
            border = 'rounded',
            title = 'Telescope lazy',
            title_pos = 'center',
            width = 0.5,
            height = 0.5,
          },
          -- Other telescope configuration options
        },
        file_browser = {
          -- theme = 'ivy',
          -- disables netrw and use telescope-file-browser in its place
          hijack_netrw = true,
          mappings = {
            ['i'] = {
              -- your custom insert mode mappings
              ['<C-l>'] = ts_actions.select_default,
              ['<C-h>'] = fb_actions.goto_parent_dir,
              ['<C-o>'] = fb_actions.open,
              ['<C-e>'] = fb_actions.goto_home_dir,
              ['<C-w>'] = fb_actions.goto_cwd,
              ['<C-t>'] = fb_actions.change_cwd,
              ['<C-f>'] = fb_actions.toggle_browser,
              ['<C-s>'] = fb_actions.toggle_all,
              ['<A-c>'] = false,
              ['<S-CR>'] = false,
              ['<A-r>'] = false,
              ['<A-m>'] = false,
              ['<A-y>'] = false,
              ['<A-d>'] = false,
              ['<C-g>'] = false,
            },
            ['n'] = {
              ['l'] = ts_actions.select_default,
              ['h'] = fb_actions.goto_parent_dir,
              ['H'] = fb_actions.toggle_hidden,
              ['c'] = fb_actions.create,
              ['r'] = fb_actions.rename,
              ['m'] = fb_actions.move,
              ['y'] = fb_actions.copy,
              ['d'] = fb_actions.remove,
              ['o'] = fb_actions.open,
              ['e'] = fb_actions.goto_home_dir,
              ['w'] = fb_actions.goto_cwd,
              ['t'] = fb_actions.change_cwd,
              ['f'] = fb_actions.toggle_browser,
              ['s'] = fb_actions.toggle_all,
              ['g'] = false,
            },
          },
        },
      }
    })
    require('telescope').load_extension('egrepify')
    require('telescope').load_extension('fzf')
    require('telescope').load_extension('undo')
    require('telescope').load_extension('glyph')
    require('telescope').load_extension('neoclip')
    require('telescope').load_extension('ui-select')
    require('telescope').load_extension('lazy')
    require('telescope').load_extension('file_browser')
    require('telescope').load_extension('luasnip')

    keysRegisterSearch()
  end,
}})
