-- ------------------------------------------------------------------------------------------------------------------------------
-- Improvements
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  'soraliu/vim-argwrap', -- Split arguments into multiple lines
  'imsnif/kdl.vim', -- KDL language syntax & indent
  'mg979/vim-visual-multi', -- Multiple cursors plugin
  'wellle/targets.vim', -- Expands on the idea of simple commands like di'
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
    'rcarriga/nvim-notify', -- better UI of vim.notify
    config = function()
      vim.notify = require('notify')
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
    config = function()
      require('gomove').setup({
        -- whether or not to map default key bindings, (true/false)
        map_defaults = false,
        -- whether or not to reindent lines moved vertically (true/false)
        reindent = true,
        -- whether or not to undojoin same direction moves (true/false)
        undojoin = true,
        -- whether to not to move past end column when moving blocks horizontally, (true/false)
        move_past_end_col = false,
      })

      keysRegisterGomove()
    end,
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
    'NvChad/nvim-colorizer.lua', -- show colors
    config = function()
      require('colorizer').setup()
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
  'numToStr/Comment.nvim',
  lazy = false,
  dependencies = {
    'JoosepAlviste/nvim-ts-context-commentstring',
    config = function()
      require('ts_context_commentstring').setup({
        enable_autocmd = false,
      })
    end,
  },
  config = function()
    local keymaps = keysPluginComment()

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
