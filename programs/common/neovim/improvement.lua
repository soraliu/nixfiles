
-- ------------------------------------------------------------------------------------------------------------------------------
-- Auto pair brackets, quotes, etc
-- TODO: support auto pair xml tag, lua function end, etc
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  'windwp/nvim-autopairs',
  event = "InsertEnter",
  config = true,
  opts = {
    enable_check_bracket_line = false,
    check_ts = true,
  },
})


-- ------------------------------------------------------------------------------------------------------------------------------
-- Split arguments into multiple lines
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  "soraliu/vim-argwrap",
  config = function()
    vim.keymap.set('n', 'ga', ":ArgWrap<CR>", { silent = true })
  end
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
    vim.keymap.set('x', '<c-_>', '<Plug>(comment_toggle_linewise_visual)')
    vim.keymap.set('x', '<c-\\>', '<Plug>(comment_toggle_blockwise_visual)')

    require('Comment').setup({
      ignore = '^$',
      ---LHS of toggle mappings in NORMAL mode
      toggler = {
          ---Line-comment toggle keymap
          line = '<c-_>',
          ---Block-comment toggle keymap
          block = '<c-\\>',
      },
      ---LHS of operator-pending mappings in NORMAL and VISUAL mode
      opleader = {
          ---Line-comment keymap
          line = 'gc',
          ---Block-comment keymap
          block = 'gb',
      },
      pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
    })
  end,
})


-- ------------------------------------------------------------------------------------------------------------------------------
-- support to show todo/hack/fix/note/warning etc
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local todo = require("todo-comments")

    todo.setup({
      keywords = {
        FIX = {
          icon = " ", -- icon used for the sign, and in search results
          color = "error", -- can be a hex color, or a named color (see below)
          alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
          -- signs = false, -- configure signs for some keywords individually
        },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = "󱅰 ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
    })

    vim.keymap.set('n', '<space>n', ":TodoTelescope<CR>")
  end,
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  }
})


-- ------------------------------------------------------------------------------------------------------------------------------
-- support edit file separate on markdown codeblock
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  "AckslD/nvim-FeMaco.lua",
  config = function()
    vim.keymap.set('n', '<space>ei', ":FeMaco<CR>")

    require("femaco").setup()
  end,
})

