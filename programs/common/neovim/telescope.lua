
-- ------------------------------------------------------------------------------------------------------------------------------
-- Search Engine
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.5',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<space>o', builtin.find_files)
    vim.keymap.set('n', '<space>b', builtin.buffers)
    vim.keymap.set('n', '<space>s', builtin.live_grep)
    vim.keymap.set('n', '<space>l', builtin.grep_string)
    vim.keymap.set('n', '<space>h', builtin.help_tags)
    vim.keymap.set('n', '<space>p', ":Telescope<CR>")

    require('telescope').setup{
      defaults = {
        -- Default configuration for telescope goes here:
        -- config_key = value,
        mappings = {
          i = {
            -- map actions.which_key to <C-h> (default: <C-/>)
            -- actions.which_key shows the mappings for your picker,
            -- e.g. git_{create, delete, ...}_branch for the git_branches picker
            ["<c-j>"] = "move_selection_next",
            ["<c-k>"] = "move_selection_previous",
            ["kj"] = "close",
         },
        },
      },
      pickers = {
        -- Default configuration for builtin pickers goes here:
        -- picker_name = {
        --   picker_config_key = value,
        --   ...
        -- }
        -- Now the picker_config_key will be applied every time you call this
        -- builtin picker
      },
      extensions = {
        -- Your extension configuration goes here:
        -- extension_name = {
        --   extension_config_key = value,
        -- }
        -- please take a look at the readme of the extension you want to configure
      }
    }
  end,
})

