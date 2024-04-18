-- ------------------------------------------------------------------------------------------------------------------------------
-- Configure Neovim statusline
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('lualine').setup({
      options = {
        icons_enabled = true,
        theme = 'auto',
        -- component_separators = { left = '', right = ''},
        -- section_separators = { left = '', right = ''},
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {
          statusline = {},
          winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = false,
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
        },
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = {
          '@branch@',
          'diff',
          {
            'diagnostics',
            symbols = { error = 'E', warn = 'W', info = 'I', hint = 'H' },
          },
          {
            function()
              return require('grapple').name_or_index()
            end,
            icon = '󰛢 ',
            cond = function()
              return package.loaded['grapple'] and require('grapple').exists()
            end,
          },
        },
        lualine_c = {
          { 'filename', path = 1 },
          {
            -- Insert mid section. You can make any number of sections in neovim :)
            -- for lualine it's any number greater then 2
            function()
              return '%='
            end,
          },
          {
            'copilot',
            -- Default values
            symbols = {
              status = {
                icons = {
                  enabled = ' Copilot: enalbed',
                  sleep = ' Copilot: sleep', -- auto-trigger disabled
                  disabled = ' Copilot: disabled',
                  warning = ' Copilot: warning',
                  unknown = ' Copilot: unknown',
                },
                hl = {
                  enabled = '#FF5555',
                  sleep = '#50FA7B',
                  disabled = '#6272A4',
                  warning = '#FFB86C',
                  unknown = '#AEB7D0',
                },
              },
              spinners = require('copilot-lualine.spinners').dots,
              spinner_color = '#50FA7B',
            },
            show_colors = true,
            show_loading = true,
          },
          {
            function()
              return '│'
            end,
            color = {
              fg = '#F8FDFD',
            },
          },
          {
            -- Lsp server name .
            function()
              local msg = 'None'
              local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
              local clients = vim.lsp.get_active_clients()
              if next(clients) == nil then
                return msg
              end

              local names = {}
              for _, client in ipairs(clients) do
                local filetypes = client.config.filetypes
                if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                  table.insert(names, client.name)
                end
              end
              if #names > 0 then
                return table.concat(names, ', ')
              end

              return msg
            end,
            icon = ' LSP:',
            color = {
              fg = '#fc5d7c',
              -- gui = 'bold'
            },
          },
        },
        lualine_x = { '@encoding@', '@fileformat@', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {},
      winbar = {},
      inactive_winbar = {},
      extensions = {},
    })
  end,
})
