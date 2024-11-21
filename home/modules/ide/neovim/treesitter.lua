-- ------------------------------------------------------------------------------------------------------------------------------
-- Syntax
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    'NoahTheDuke/vim-just',
    ft = { 'just' },
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      local configs = require('nvim-treesitter.configs')

      configs.setup({
        ensure_installed = {
          -- Doc
          'markdown',
          'markdown_inline',

          -- Editor
          'vim',
          'vimdoc',
          'lua',

          -- Conf
          'just',
          'json',
          'jsonc',
          'yaml',
          'xml',
          'kdl',

          -- DevOps
          'nix',
          'bash',
          'c',

          -- BE
          'go',
          'gomod',
          'python',

          -- FE
          'html',
          'css',
          'scss',
          'jsdoc',
          'javascript',
          'typescript',
          'tsx',
          'vue',
          'kotlin',
        },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = { -- set to `false` to disable one of the mappings
            -- init_selection = "]]",
            -- scope_incremental = "]]",
            -- because of the conflict with chatgpt, I have to change the keymaps
            init_selection = false,
            scope_incremental = false,
            node_incremental = '}',
            node_decremental = '{',
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            include_surrounding_whitespace = false,
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
              ['aa'] = '@parameter.outer',
              ['ia'] = '@parameter.inner',
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ab'] = '@block.outer',
              ['ib'] = '@block.inner',
              ['ai'] = '@conditional.outer',
              ['ii'] = '@conditional.inner',
              ['al'] = '@loop.outer',
              ['il'] = '@loop.inner',
            },
            selection_modes = {
              ['@class.outer'] = '<c-v>', -- blockwise
              ['@parameter.outer'] = 'v', -- charwise
              ['@function.outer'] = 'V', -- linewise
              ['@block.outer'] = 'V', -- linewise
              ['@conditional.outer'] = 'V', -- linewise
              ['@loop.outer'] = 'V', -- linewise
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              [']c'] = '@class.outer',
              [']a'] = '@parameter.outer',
              [']f'] = '@function.outer',
              [']b'] = '@block.outer',
              [']i'] = '@conditional.outer',
              [']l'] = '@loop.outer',
            },
            goto_next_end = {
              [']F'] = '@function.outer',
              [']A'] = '@parameter.outer',
              [']C'] = '@class.outer',
              [']B'] = '@block.outer',
              [']I'] = '@conditional.outer',
              [']L'] = '@loop.outer',
            },
            goto_previous_start = {
              ['[f'] = '@function.outer',
              ['[a'] = '@parameter.outer',
              ['[c'] = '@class.outer',
              ['[b'] = '@block.outer',
              ['[i'] = '@conditional.outer',
              ['[l'] = '@loop.outer',
            },
            goto_previous_end = {
              ['[F'] = '@function.outer',
              ['[A'] = '@parameter.outer',
              ['[C'] = '@class.outer',
              ['[B'] = '@block.outer',
              ['[I'] = '@conditional.outer',
              ['[L'] = '@loop.outer',
            },
          },
        },
      })

      keysRegisterTSMove()

      vim.cmd([[
        set foldmethod=expr
        set foldexpr=nvim_treesitter#foldexpr()
        set nofoldenable                     " Disable folding at startup.
      ]])
    end,
  },
})
