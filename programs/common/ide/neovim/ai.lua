-- ------------------------------------------------------------------------------------------------------------------------------
-- Copilot, ChatGPT
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    'zbirenbaum/copilot-cmp',
    dependencies = {
      'AndreM222/copilot-lualine',
      {
        'zbirenbaum/copilot.lua',
        cmd = 'Copilot',
        event = 'InsertEnter',
        config = function()
          require('copilot').setup({
            panel = {
              enabled = true,
              auto_refresh = false,
              keymap = {
                jump_prev = '[s',
                jump_next = ']s',
                accept = '<CR>',
                refresh = '<c-r>',
                open = '<c-p>',
              },
              layout = {
                position = 'bottom', -- | top | left | right
                ratio = 0.4,
              },
            },
            suggestion = {
              enabled = true,
              auto_trigger = false,
              debounce = 75,
              keymap = {
                accept = '<c-f>',
                accept_word = false,
                accept_line = false,
                next = '<c-]>',
                prev = '<c-[>',
                dismiss = '<c-e>',
              },
            },
          })

          local panel = require('copilot.panel')
          vim.keymap.set('n', '<c-p>', panel.open, { desc = 'Copilot - Open Panel' })
        end,
      },
    },
    config = function()
      require('copilot_cmp').setup()
    end,
  },
  {
    'jackMort/ChatGPT.nvim',
    event = 'VeryLazy',
    config = function()
      require('chatgpt').setup({
        edit_with_instructions = {
          diff = false,
          keymaps = {
            close = '<C-c>',
            accept = '<C-y>',
            toggle_diff = '<C-d>',
            toggle_settings = '<C-o>',
            toggle_help = '<C-h>',
            cycle_windows = '<Tab>',
            use_output_as_input = '<C-r>',
          },
        },
        chat = {
          question_sign = '', -- 🙂
          answer_sign = 'ﮧ', -- 🤖
          border_left_sign = '',
          border_right_sign = '',
          max_line_length = 120,
          sessions_window = {
            active_sign = '  ',
            inactive_sign = '  ',
            current_line_sign = '  ',
          },
          keymaps = {
            close = '<C-c>',
            yank_last = '<C-y>',
            yank_last_code = '<C-k>',
            scroll_up = '<C-u>',
            scroll_down = '<C-d>',
            new_session = '<C-n>',
            cycle_windows = '<Tab>',
            cycle_modes = '<C-f>',
            next_message = '<C-j>',
            prev_message = '<C-k>',
            select_session = '<Space>',
            rename_session = 'r',
            delete_session = 'd',
            draft_message = '<C-r>',
            edit_message = 'e',
            delete_message = 'd',
            toggle_settings = '<C-o>',
            toggle_sessions = '<C-p>',
            toggle_help = '<C-h>',
            toggle_message_role = '<C-r>',
            toggle_system_role_open = '<C-s>',
            stop_generating = '<C-x>',
          },
        },
        popup_input = {
          prompt = '  ',
          border = {
            highlight = 'FloatBorder',
            style = 'rounded',
            text = {
              top_align = 'center',
              top = ' Prompt ',
            },
          },
          win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
          },
          submit = '<Enter>',
          submit_n = '<Enter>',
          max_visible_lines = 20,
        },
        openai_params = {
          model = 'gpt-3.5-turbo',
          max_tokens = 3000,
        },
        openai_edit_params = {
          model = 'gpt-3.5-turbo',
        },
      })

      keysRegisterChatGPT()
    end,
    dependencies = {
      'MunifTanjim/nui.nvim',
      'nvim-lua/plenary.nvim',
      'folke/trouble.nvim',
      'nvim-telescope/telescope.nvim',
    },
  },
})
