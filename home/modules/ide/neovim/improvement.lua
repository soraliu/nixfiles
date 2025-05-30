-- ------------------------------------------------------------------------------------------------------------------------------
-- Improvements
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  'soraliu/vim-argwrap',    -- Split arguments into multiple lines
  'imsnif/kdl.vim',         -- KDL language syntax & indent
  'mg979/vim-visual-multi', -- Multiple cursors plugin
  'wellle/targets.vim',     -- Expands on the idea of simple commands like di'
  {

    'hedyhli/outline.nvim',
    lazy = true,
    cmd = { 'Outline', 'OutlineOpen' },
    keys = {
      { '<leader>to', '<cmd>Outline<CR>', desc = 'Toggle outline' },
    },
    opts = {
      -- Your setup opts here
      outline_window = {
        position = 'right',
        width = 20,
      },
    },
  },
  {
    'folke/zen-mode.nvim',
    opts = {
      window = {
        backdrop = 1, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
        width = 128,  -- width of the Zen window
        height = 1,   -- height of the Zen window
        options = {
          -- signcolumn = "no", -- disable signcolumn
          -- number = false, -- disable number column
          -- relativenumber = false, -- disable relative numbers
          -- cursorline = false, -- disable cursorline
          -- cursorcolumn = false, -- disable cursor column
          -- foldcolumn = "0", -- disable fold column
          -- list = false, -- disable whitespace characters
        },
      },
      plugins = {
        options = {
          enabled = true,
          ruler = false,   -- disables the ruler text in the cmd line area
          showcmd = false, -- disables the command in the last line of the screen
          -- you may turn on/off statusline in zen mode by setting 'laststatus'
          -- statusline will be shown only if 'laststatus' == 3
          laststatus = 0,                  -- turn off the statusline in zen mode
        },
        gitsigns = { enabled = false },    -- disables git signs
        diagnostics = { enabled = false }, -- disables diagnostics
      },
    },
  },
  {
    'kevinhwang91/nvim-hlslens', -- Highlight the lens of the search result
    config = function()
      require('hlslens').setup()

      local opts = { noremap = true, silent = true }

      vim.api.nvim_set_keymap(
        'n',
        'n',
        [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
        opts
      )
      vim.api.nvim_set_keymap(
        'n',
        'N',
        [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
        opts
      )
      vim.api.nvim_set_keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], opts)
      vim.api.nvim_set_keymap('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], opts)
      vim.api.nvim_set_keymap('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], opts)
      vim.api.nvim_set_keymap('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], opts)
    end,
  },
  {
    'nvim-pack/nvim-spectre',
    config = function()
      require('spectre').setup({
        mapping = keysPluginSpectre(),
        default = {
          find = {
            cmd = 'rg',
            options = { 'ignore-case' },
          },
          replace = {
            cmd = 'sd',
          },
        },
      })
    end,
  },
  {
    'axieax/urlview.nvim',
    config = function()
      require('urlview').setup({
        -- Prompt title (`<context> <default_title>`, e.g. `Buffer Links:`)
        default_title = 'Links:',
        -- Default picker to display links with
        -- Options: "native" (vim.ui.select) or "telescope"
        default_picker = 'native',
        -- Set the default protocol for us to prefix URLs with if they don't start with http/https
        default_prefix = 'https://',
        -- Command or method to open links with
        -- Options: "netrw", "system" (default OS browser), "clipboard"; or "firefox", "chromium" etc.
        -- By default, this is "netrw", or "system" if netrw is disabled
        default_action = 'system',
        -- Keymaps for jumping to previous / next URL in buffer
        jump = {
          prev = '',
          next = '',
        },
      })
    end,
  },
  {
    'kylechui/nvim-surround',
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    config = function()
      require('nvim-surround').setup({
        -- Configuration here, or leave empty to use defaults
      })
    end,
  },
  {
    'booperlv/nvim-gomove', -- move/duplicate lines
    opts = {
      -- whether or not to map default key bindings, (true/false)
      map_defaults = false,
      -- whether or not to reindent lines moved vertically (true/false)
      reindent = true,
      -- whether or not to undojoin same direction moves (true/false)
      undojoin = true,
      -- whether to not to move past end column when moving blocks horizontally, (true/false)
      move_past_end_col = false,
    },
    keys = {
      { '<space>dh', '<Plug>GoNSDLeft',  mode = 'n', desc = 'Duplicate Left' },
      { '<space>dj', '<Plug>GoNSDDown',  mode = 'n', desc = 'Duplicate Down' },
      { '<space>dk', '<Plug>GoNSDUp',    mode = 'n', desc = 'Duplicate Up' },
      { '<space>dl', '<Plug>GoNSDRight', mode = 'n', desc = 'Duplicate Right' },
      { '<C-h>',     '<Plug>GoNSMLeft',  mode = 'n', desc = 'Move Left' },
      { '<C-j>',     '<Plug>GoNSMDown',  mode = 'n', desc = 'Move Down' },
      { '<C-k>',     '<Plug>GoNSMUp',    mode = 'n', desc = 'Move Up' },
      { '<C-l>',     '<Plug>GoNSMRight', mode = 'n', desc = 'Move Right' },

      { '<space>dh', '<Plug>GoVSDLeft',  mode = 'x', desc = 'Duplicate Left' },
      { '<space>dj', '<Plug>GoVSDDown',  mode = 'x', desc = 'Duplicate Down' },
      { '<space>dk', '<Plug>GoVSDUp',    mode = 'x', desc = 'Duplicate Up' },
      { '<space>dl', '<Plug>GoVSDRight', mode = 'x', desc = 'Duplicate Right' },
      { '<C-h>',     '<Plug>GoVSMLeft',  mode = 'x', desc = 'Move Left' },
      { '<C-j>',     '<Plug>GoVSMDown',  mode = 'x', desc = 'Move Down' },
      { '<C-k>',     '<Plug>GoVSMUp',    mode = 'x', desc = 'Move Up' },
      { '<C-l>',     '<Plug>GoVSMRight', mode = 'x', desc = 'Move Right' },
    },
  },
  {
    'Yggdroot/indentLine', -- display the indention levels with thin vertical lines
    config = function()
      vim.cmd([[
        let g:indentLine_char = '|'
      ]])
    end,
  },
  {
    'junegunn/vim-easy-align', -- A simple, easy-to-use Vim alignment plugin.
    config = function()
      keysRegisterEasyAlign()
    end,
  },
  {
    'm4xshen/smartcolumn.nvim', -- A Neovim plugin hiding your colorcolumn when unneeded
    opts = {
      colorcolumn = '360',
      -- custom_colorcolumn = {
      --   typescript = "180",
      -- },
    },
  },
  {
    'smoka7/hop.nvim', -- easy motion alternative
    version = '*',
    opts = {},
    config = function()
      require('hop').setup({})

      keysRegisterEasyMotion()
    end,
  },
  {
    'goolord/alpha-nvim', -- Show a welcome page
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('alpha').setup(require('alpha.themes.startify').config)
    end,
  },
  {
    'AckslD/nvim-FeMaco.lua', -- support edit file separate on markdown codeblock
    config = function()
      require('femaco').setup()
    end,
  },
  {
    'powerman/vim-plugin-AnsiEsc', -- conceal Ansi escape sequences but will cause subsequent text to be colored
    cnfig = function()
      -- TODO: check usability
      vim.cmd([[
        autocmd BufNewFile,BufRead *.ansi.log call timer_start(100, { tid -> execute('AnsiEsc')})
      ]])
    end,
  },
  {
    'cappyzawa/trim.nvim',
    config = function()
      require('trim').setup({
        ft_blocklist = {},
        patterns = {},
        trim_on_write = true,
        trim_trailing = true,
        trim_last_line = true,
        trim_first_line = true,
        highlight = false,
        highlight_bg = '#ff0000', -- or 'red'
        highlight_ctermbg = 'red',
      })
    end,
  },
})

-- ------------------------------------------------------------------------------------------------------------------------------
-- comment
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    'numToStr/Comment.nvim',
    lazy = true,
    keys = {
      { '<c-/>',  '<Plug>(comment_toggle_linewise)',         mode = 'n' },
      { '<c-\\>', '<Plug>(comment_toggle_blockwise)',        mode = 'n' },
      { '<c-/>',  '<Plug>(comment_toggle_linewise_visual)',  mode = 'x' },
      { '<c-\\>', '<Plug>(comment_toggle_blockwise_visual)', mode = 'x' },
    },
    config = function()
      local keymaps = {
        ---LHS of toggle mappings in NORMAL mode
        toggler = {
          ---Line-comment toggle keymap
          line = '<c-/>',
          ---Block-comment toggle keymap
          block = '<c-\\>',
        },
        ---LHS of operator-pending mappings in NORMAL and VISUAL mode
        opleader = {
          ---Line-comment toggle keymap
          line = '<c-/>',
          ---Block-comment toggle keymap
          block = '<c-\\>',
        },
      }

      function mergeTables(t1, t2)
        for k, v in pairs(t2) do
          t1[k] = v
        end
        return t1
      end

      require('Comment').setup(mergeTables({
        ignore = '^$',
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      }, keymaps))
    end,
  },
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    lazy = true,
    opts = {

      enable_autocmd = false,
    },
  },
})

-- ------------------------------------------------------------------------------------------------------------------------------
-- support to show todo/hack/fix/note/warning etc
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  'folke/todo-comments.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local todo = require('todo-comments')

    todo.setup({
      keywords = {
        FIX = {
          icon = ' ', -- icon used for the sign, and in search results
          color = 'error', -- can be a hex color, or a named color (see below)
          alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE' }, -- a set of other keywords that all map to this FIX keywords
          -- signs = false, -- configure signs for some keywords individually
        },
        TODO = { icon = ' ', color = 'info' },
        HACK = { icon = ' ', color = 'warning' },
        WARN = { icon = ' ', color = 'warning', alt = { 'WARNING', 'XXX' } },
        PERF = { icon = ' ', alt = { 'OPTIM', 'PERFORMANCE', 'OPTIMIZE' } },
        NOTE = { icon = '󱅰 ', color = 'hint', alt = { 'INFO' } },
        TEST = { icon = '⏲ ', color = 'test', alt = { 'TESTING', 'PASSED', 'FAILED' } },
      },
    })
  end,
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  },
})
