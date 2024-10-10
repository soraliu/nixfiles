-- ------------------------------------------------------------------------------------------------------------------------------
-- Git
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    'lewis6991/gitsigns.nvim',
    dependencies = {
      'tpope/vim-fugitive',
      {
        'ruifm/gitlinker.nvim',
        dependencies = {
          'nvim-lua/plenary.nvim',
        },
        config = function()
          require('gitlinker').setup({
            mappings = nil,
          })
        end,
      },
    },
    config = function()
      require('gitsigns').setup({
        signs = {
          add = { text = '│' },
          change = { text = '│' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
          untracked = { text = '┆' },
        },
        signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
        numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
        linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
        word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
        current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
          delay = 320,
          ignore_whitespace = false,
          virt_text_priority = 100,
        },
        current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',

        on_attach = function(bufnr)
          vim.cmd([[
            highlight gitsignscurrentlineblame guifg=#7f8490
          ]])
        end,

        keysRegisterGit(package.loaded.gitsigns),
      })
    end,
  },
  {
    'kdheepak/lazygit.nvim',
    lazy = true,
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    -- optional for floating window border decoration
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { '<space>vl', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
    },
  },
})
