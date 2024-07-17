-- ------------------------------------------------------------------------------------------------------------------------------
-- Configure Neovim statusline
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    'akinsho/bufferline.nvim',
    lazy = false,
    init = function()
      vim.opt.termguicolors = true
    end,
    opts = {
      options = {
        offsets = {
          {
            filetype = 'NvimTree',
            text = 'File Explorer',
            text_align = 'center',
            separator = true,
          },
        },

        numbers = 'ordinal',
        show_buffer_close_icons = false,

        diagnostics = 'nvim_lsp',
        diagnostics_indicator = function(count, level, diagnostics_dict, context)
          local icon = level:match('error') and ' ' or ' '
          return ' ' .. icon .. count
        end,
      },
    },
    keys = {
      { '<space>1',  '<cmd>BufferLineGoToBuffer 1<cr>',  mode = { 'n' }, desc = 'Go to Buffer 1' },
      { '<space>2',  '<cmd>BufferLineGoToBuffer 2<cr>',  mode = { 'n' }, desc = 'Go to Buffer 2' },
      { '<space>3',  '<cmd>BufferLineGoToBuffer 3<cr>',  mode = { 'n' }, desc = 'Go to Buffer 3' },
      { '<space>4',  '<cmd>BufferLineGoToBuffer 4<cr>',  mode = { 'n' }, desc = 'Go to Buffer 4' },
      { '<space>5',  '<cmd>BufferLineGoToBuffer 5<cr>',  mode = { 'n' }, desc = 'Go to Buffer 5' },
      { '<space>6',  '<cmd>BufferLineGoToBuffer 6<cr>',  mode = { 'n' }, desc = 'Go to Buffer 6' },
      { '<space>7',  '<cmd>BufferLineGoToBuffer 7<cr>',  mode = { 'n' }, desc = 'Go to Buffer 7' },
      { '<space>8',  '<cmd>BufferLineGoToBuffer 8<cr>',  mode = { 'n' }, desc = 'Go to Buffer 8' },
      { '<space>9',  '<cmd>BufferLineGoToBuffer 9<cr>',  mode = { 'n' }, desc = 'Go to Buffer 9' },
      { '<space>$',  '<cmd>BufferLineGoToBuffer -1<cr>', mode = { 'n' }, desc = 'Go to Buffer -1' },
      { '<space>[',  '<cmd>BufferLineCyclePrev<cr>',     mode = { 'n' }, desc = 'Prev Buffer' },
      { '<space>]',  '<cmd>BufferLineCycleNext<cr>',     mode = { 'n' }, desc = 'Next Buffer' },

      { '<space>b[', '<cmd>BufferLineMovePrev<cr>',      mode = { 'n' }, desc = 'Move to Prev' },
      { '<space>b]', '<cmd>BufferLineMoveNext<cr>',      mode = { 'n' }, desc = 'Move to Next' },
      { '<space>bp', '<cmd>BufferLinePick<cr>',          mode = { 'n' }, desc = 'Pick a Buffer' },
      { '<space>bo', '<cmd>BufferLineCloseOthers<cr>',   mode = { 'n' }, desc = 'Close Other Buffers' },
    },
  },
  {
    'utilyre/barbecue.nvim',
    name = 'barbecue',
    opts = {
      create_autocmd = false, -- prevent barbecue from updating itself automatically
    },
    init = function()
      vim.api.nvim_create_autocmd({
        'WinResized',
        'BufWinEnter',
        'CursorHold',
        'InsertLeave',
      }, {
        group = vim.api.nvim_create_augroup('barbecue.updater', {}),
        callback = function()
          require('barbecue.ui').update()
        end,
      })
    end,
  },
  { 'nvim-tree/nvim-web-devicons', lazy = true },
  { 'SmiteshP/nvim-navic',         lazy = true },
})
