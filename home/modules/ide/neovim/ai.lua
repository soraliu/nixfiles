-- ------------------------------------------------------------------------------------------------------------------------------
-- Copilot
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  { 'zbirenbaum/copilot-cmp',    opts = {} },
  { 'AndreM222/copilot-lualine', lazy = true },
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      filetypes = {
        markdown = true,
        sh = function()
          if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), '^%.env.*') then
            -- disable for .env files
            return false
          end
          return true
        end,
      },
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
    },
    keys = {
      { '<c-p>', '<cmd>Copilot panel<cr>', { mode = 'n', desc = 'Copilot - Open Panel' } },
    },
  },
})

-- ------------------------------------------------------------------------------------------------------------------------------
-- ChatGPT
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  { 'MunifTanjim/nui.nvim',  lazy = true },
  { 'nvim-lua/plenary.nvim', lazy = true },
  { 'folke/trouble.nvim',    lazy = true },
  {
    'jackMort/ChatGPT.nvim',
    event = 'VeryLazy',
    opts = {
      edit_with_instructions = {
        diff = false,
        keymaps = {
          close = '<C-c>',
          accept = '<C-y>',
          toggle_diff = '<C-d>',
          toggle_settings = '<C-o>',
          toggle_help = '<C-_>',
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
          toggle_help = '<C-_>',
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
    },
    keys = {
      { '<space>cc', '<cmd>ChatGPT<cr>',                       mode = { 'n', 'v' }, desc = 'ChatGPT' },
      {
        '<space>ce',
        '<cmd>ChatGPTEditWithInstruction<cr>',
        mode = { 'n', 'v' },
        desc = 'Edit with instruction',
      },
      { '<space>cg', '<cmd>ChatGPTRun grammar_correction<cr>', mode = { 'n', 'v' }, desc = 'Grammar Correction' },
      { '<space>ct', '<cmd>ChatGPTRun translate<cr>',          mode = { 'n', 'v' }, desc = 'Translate' },
      { '<space>ck', '<cmd>ChatGPTRun keywords<cr>',           mode = { 'n', 'v' }, desc = 'Keywords' },
      { '<space>cd', '<cmd>ChatGPTRun docstring<cr>',          mode = { 'n', 'v' }, desc = 'Docstring' },
      { '<space>ca', '<cmd>ChatGPTRun add_tests<cr>',          mode = { 'n', 'v' }, desc = 'Add Tests' },
      { '<space>co', '<cmd>ChatGPTRun optimize_code<cr>',      mode = { 'n', 'v' }, desc = 'Optimize Code' },
      { '<space>cs', '<cmd>ChatGPTRun summarize<cr>',          mode = { 'n', 'v' }, desc = 'Summarize' },
      { '<space>cf', '<cmd>ChatGPTRun fix_bugs<cr>',           mode = { 'n', 'v' }, desc = 'Fix Bugs' },
      { '<space>cx', '<cmd>ChatGPTRun explain_code<cr>',       mode = { 'n', 'v' }, desc = 'Explain Code' },
      { '<space>cr', '<cmd>ChatGPTRun roxygen_edit<cr>',       mode = { 'n', 'v' }, desc = 'Roxygen Edit' },
      {
        '<space>cl',
        '<cmd>ChatGPTRun code_readability_analysis<cr>',
        mode = { 'n', 'v' },
        desc = 'Code Readability Analysis',
      },
    },
  },
})
