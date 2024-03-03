
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
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<space>fp', ":Telescope<CR>")
        vim.keymap.set('n', '<space>fo', builtin.oldfiles)
        vim.keymap.set('n', '<space>fl', builtin.find_files, { hidden = ture })
        vim.keymap.set('n', '<space>fb', builtin.buffers)
        vim.keymap.set('n', '<space>fw', builtin.grep_string)
        vim.keymap.set('n', '<space>fk', builtin.keymaps)
        vim.keymap.set('n', '<space>fh', builtin.help_tags)
        vim.keymap.set('n', '<space>fm', builtin.commands)
        vim.keymap.set('n', '<space>fs', ":Telescope egrepify<CR>")

        -- LSP
        vim.keymap.set('n', '<space>fd', builtin.diagnostics)
        vim.keymap.set('n', '<space>fj', builtin.lsp_references)
        vim.keymap.set('n', '<space>fi', builtin.lsp_implementations)

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
                ["<esc>"] = "close",
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

        require "telescope".load_extension "egrepify"
      end,
    },
  },
})

