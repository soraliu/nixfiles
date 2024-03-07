
-- ------------------------------------------------------------------------------------------------------------------------------
-- Improvements
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  'soraliu/vim-argwrap', -- Split arguments into multiple lines
  {
    'smoka7/hop.nvim',
    version = "*",
    opts = {},
    config = function()
      require('hop').setup({})

      keysRegisterEasyMotion()
    end,
  },
  {
    'mg979/vim-visual-multi',
    branch = 'master',
  },
  {
    'kylechui/nvim-surround',
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    config = function()
      require('nvim-surround').setup({
        -- Configuration here, or leave empty to use defaults
      })
    end
  },
  {
    -- Auto pair brackets, quotes, etc
    -- TODO: support auto pair xml tag, lua function end, etc
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = true,
    opts = {
      enable_check_bracket_line = false,
      check_ts = true,
    },
  },
  {
    -- Show a welcome page
    'goolord/alpha-nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function ()
      require'alpha'.setup(require'alpha.themes.startify'.config)
    end
  },
  {
    -- support edit file separate on markdown codeblock
    'AckslD/nvim-FeMaco.lua',
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
      require('ts_context_commentstring').setup {
        enable_autocmd = false,
      }
    end,
  },
  config = function()
    local keymaps = keysPluginComment()

    function mergeTables(t1, t2)
        for k,v in pairs(t2) do
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
  }
})
