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
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
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
        }
      },
      sections = {
        lualine_a = {'mode'},
        lualine_b = {
          'branch',
          'diff',
          {
            'diagnostics',
            symbols = {error = 'E', warn = 'W', info = 'I', hint = 'H'},
          },
        },
        lualine_c = {{ 'filename', path = 1,  }, {
          -- Insert mid section. You can make any number of sections in neovim :)
          -- for lualine it's any number greater then 2
          function()
            return '%='
          end,
        }, {
          'copilot',
          -- Default values
          symbols = {
              status = {
                  icons = {
                      enabled = " ",
                      sleep = " ",   -- auto-trigger disabled
                      disabled = " ",
                      warning = " ",
                      unknown = " "
                  },
                  hl = {
                      enabled = "#50FA7B",
                      sleep = "#AEB7D0",
                      disabled = "#6272A4",
                      warning = "#FFB86C",
                      unknown = "#FF5555"
                  }
              },
              spinners = require("copilot-lualine.spinners").dots,
              spinner_color = "#50FA7B"
          },
          show_colors = true,
          show_loading = true,
        }, {
          -- Lsp server name .
          function()
            local msg = 'No Active Lsp'
            local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
            local clients = vim.lsp.get_active_clients()
            if next(clients) == nil then
              return msg
            end
            for _, client in ipairs(clients) do
              local filetypes = client.config.filetypes
              if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                return client.name
              end
            end
            return msg
          end,
          icon = ' LSP:',
          color = {
            fg = '#fc5d7c',
            -- gui = 'bold'
          },
        }},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
      },
      tabline = {},
      winbar = {},
      inactive_winbar = {},
      extensions = {}
    })
  end,
})
