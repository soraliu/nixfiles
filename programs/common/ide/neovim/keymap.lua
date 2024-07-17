-- ------------------------------------------------------------------------------------------------------------------------------
-- keymaps
-- ------------------------------------------------------------------------------------------------------------------------------
function keysRegisterBase()
  local wk = require('which-key')

  -- set <leader> to <space>
  vim.g.mapleader = ' '
  -- shortcut of <ESC>
  vim.keymap.set('n', '<ESC>', ':noh<cr><ESC>', { silent = true, noremap = true })
  vim.keymap.set('i', 'jk', '<ESC>', { nowait = true })
  -- don't copy to clipboard
  vim.keymap.set('v', 's', '"_d', { noremap = true })
  -- movement when auto wrap
  vim.keymap.set('n', 'j', 'gj', { silent = true })
  vim.keymap.set('n', 'k', 'gk', { silent = true })
  -- do/undo
  vim.keymap.set('i', '<c-u>', '<c-o>u', { noremap = true })
  vim.keymap.set('i', '<c-r>', '<c-o><c-r>', { noremap = true })
  -- command mode
  vim.api.nvim_set_keymap('c', '<C-j>', '<C-n>', {})
  vim.api.nvim_set_keymap('c', '<C-k>', '<C-p>', {})
  -- open url
  vim.keymap.set('n', 'gx', ':sil !open <c-r><c-a><cr>', { silent = true, noremap = false, desc = 'Open Url' })

  wk.add({
    mode = 'n',

    -- File Management
    { '<c-s>',     '<cmd>w<cr>',                       desc = 'Save File' },
    { '<c-q>',     '<cmd>q<cr>',                       desc = 'Quit' },

    -- Buffer Management
    { '<c-w>',     '<cmd>bp<bar>sp<bar>bn<bar>bd<cr>', desc = 'Close Buffer' },

    -- Windows Management
    { '<space>w',  group = 'Windows Management' },
    { '<space>wh', '<c-w>h',                           desc = 'Focus on Left' },
    { '<space>wl', '<c-w>l',                           desc = 'Focus on Right' },
    { '<space>wj', '<c-w>j',                           desc = 'Focus on Bottom' },
    { '<space>wk', '<c-w>k',                           desc = 'Focus on Above' },
    { '<space>wr', '<c-w>=',                           desc = 'Restore window size' },
    { '<space>wz', '<cmd>ZenMode<cr>',                 desc = 'Toggle ZenMode' },
    { '<space>w[', '<cmd>vertical resize -10<cr>',     desc = 'Vertical Size -10' },
    { '<space>w]', '<cmd>vertical resize +10<cr>',     desc = 'Vertical Size +10' },
    { '<space>w-', '<cmd>resize -10<cr>',              desc = 'Window Size -10' },
    { '<space>w+', '<cmd>resize +10<cr>',              desc = 'Window Size +10' },
  })

  wk.add({
    { '<space>d', group = 'Duplicate', mode = { 'x', 'n' } },
  })
end

function keysRegisterImprovements()
  local wk = require('which-key')

  wk.add({
    mode = 'n',
    { '<space>s',  group = 'Show Pages/Search' },
    -- Repo: goolord/alpha-nvim
    { '<space>sh', '<cmd>Alpha<cr>',                           desc = 'Show Home Page' },
    -- telescope luasnip
    { '<space>ss', '<cmd>Telescope luasnip<cr>',               desc = 'Search luasnip' },
    -- telescope notify
    { '<space>sm', '<cmd>Telescope notify<cr>',                desc = 'Search msg & notification' },
    -- Repo: soraliu/colortils.nvim
    { '<space>sc', '<cmd>Colortils css list<cr>',              desc = 'Show Css Colors' },

    { '<space>e',  group = 'Code Edit' },
    -- Repo: soraliu/vim-argwrap
    { '<space>ea', '<cmd>ArgWrap<cr>',                         desc = 'Args Wrap&Split' },
    -- Repo: AckslD/nvim-FeMaco.lua
    { '<space>em', '<cmd>FeMaco<cr>',                          desc = 'Edit Markdown Codeblock' },
    -- Repo: soraliu/colortils.nvim
    { '<space>ec', '<cmd>Colortils picker<cr>',                desc = 'Edit Color' },

    { '<space>r',  group = 'Replacement' },
    -- Repo: nvim-pack/nvim-spectre
    { '<space>ro', '<cmd>lua require("spectre").toggle()<CR>', desc = 'Open spectre replacement' },
    {
      '<space>rw',
      '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>',
      desc = 'Replace word on current file',
    },
    { '<space>rs', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', desc = 'Replace current word' },

    { '<space>t',  group = 'Toggle' },
    -- Repo: levouh/tint.nvim
    {
      '<space>ti',
      '<cmd>lua require("tint").toggle()<cr>',
      desc = 'Toggle dim inactive windown',
    },
    -- Repo: hedyhli/outline.nvim
    { '<space>to', '<cmd>Outline<CR>', desc = 'Toggle outline' },
  })

  wk.add({
    mode = 'v',
    { '<space>ro', '<esc><cmd>lua require("spectre").open_visual()<CR>', desc = 'Open spectre replacement' },
  })
end

function keysRegisterSearch()
  local wk = require('which-key')
  local builtin = require('telescope.builtin')
  local ap = require('actions-preview')

  wk.add({
    mode = 'n',
    { '<space>f',  group = 'Fuzzy Search' },

    -- Editor
    {
      '<space>fl',
      function()
        builtin.git_files({ show_untracked = true })
      end,
      desc = 'Find Files',
    },
    {
      '<space>fo',
      function()
        builtin.oldfiles({ cwd_only = true })
      end,
      desc = 'Find Recent Files',
    },
    { '<space>fp', '<cmd>Telescope<cr>',              desc = 'Telescope Home' },
    { '<space>fb', builtin.buffers,                   desc = 'Find Opened Buffers' },
    { '<space>fw', builtin.grep_string,               desc = 'Grep Cursor Word' },
    { '<space>fk', builtin.keymaps,                   desc = 'Find Keymaps' },
    { '<space>fh', builtin.help_tags,                 desc = 'Find Helps' },
    { '<space>fx', builtin.commands,                  desc = 'Find Commands' },
    { '<space>fm', '<cmd>Telescope grapple tags<cr>', desc = 'Find Grapple Tags' },
    { '<space>f,', builtin.resume,                    desc = 'Resume Last Search' },
    { '<space>fs', '<cmd>Telescope egrepify<cr>',     desc = 'Grep String' },

    -- LSP
    { '<space>fd', builtin.diagnostics,               desc = 'LSP Diagnostics' },
    { '<space>fr', builtin.lsp_references,            desc = 'LSP References' },
    { '<space>fi', builtin.lsp_implementations,       desc = 'LSP Implementations' },
    { '<space>fa', ap.code_actions,                   desc = 'LSP Actions' },

    -- Git
    { '<space>fv', builtin.git_status,                desc = 'Git Status' },

    -- Todo
    -- Repo: folke/todo-comments.nvim
    { '<space>fn', '<cmd>TodoTelescope<cr>',          desc = 'Find Todos' },

    -- Undo
    { '<space>fu', '<cmd>Telescope undo<cr>',         desc = 'Undo History' },

    -- Yank
    { '<space>fy', '<cmd>Telescope neoclip<cr>',      desc = 'Yank History' },

    -- Emoji
    { '<space>fe', builtin.symbols,                   desc = 'Emoji' },

    -- Font Emoji
    { '<space>ff', '<cmd>Telescope glyph<cr>',        desc = 'Font Emoji' },

    -- URL
    { '<space>fj', '<cmd>UrlView<cr>',                desc = 'Jump to a Url' },

    -- Lazy
    { '<space>fz', '<cmd>Telescope lazy<cr>',         desc = 'lazy.nvim' },

    -- file-browser
    {
      '<space>fg',
      function()
        require('telescope').extensions.file_browser.file_browser({ hidden = true, depth = 2 })
      end,
      desc = 'File Browser',
    },
    {
      '<space>f.',
      function()
        require('telescope').extensions.file_browser.file_browser({
          hidden = true,
          depth = 2,
          path = '%:p:h',
          select_buffer = true,
        })
      end,
      desc = 'File Browser',
    },
  })

  wk.add({
    mode = 'v',
    -- :h actions-preview.nvim-configuration
    { '<space>fa', ap.code_actions, desc = 'LSP Actions' },
  })
end

function keysRegisterMarks()
  local wk = require('which-key')

  wk.add({
    mode = 'n',

    { 'm',  group = 'Mark' },
    { 'ma', '<cmd>Grapple toggle<cr>',         desc = 'Grapple toggle tag' },
    { 'ml', '<cmd>Grapple toggle_tags<cr>',    desc = 'Grapple open tags window' },
    { 'm1', '<cmd>Grapple select index=1<cr>', desc = 'Select first tag' },
    { 'm2', '<cmd>Grapple select index=2<cr>', desc = 'Select second tag' },
    { 'm3', '<cmd>Grapple select index=3<cr>', desc = 'Select third tag' },
    { 'm4', '<cmd>Grapple select index=4<cr>', desc = 'Select fourth tag' },
    { 'm5', '<cmd>Grapple select index=5<cr>', desc = 'Select fifth tag' },
    { 'm6', '<cmd>Grapple select index=6<cr>', desc = 'Select sixth tag' },
    { 'm7', '<cmd>Grapple select index=7<cr>', desc = 'Select seventh tag' },
    { 'm8', '<cmd>Grapple select index=8<cr>', desc = 'Select eighth tag' },
    { 'm9', '<cmd>Grapple select index=9<cr>', desc = 'Select ninth tag' },
  })
end

function keysRegisterEasyMotion()
  local hop = require('hop')
  local directions = require('hop.hint').HintDirection

  vim.keymap.set('', 'gw', function()
    hop.hint_words()
  end, { desc = 'Go to a Word' })
  vim.keymap.set('', 'go', function()
    hop.hint_anywhere()
  end, { desc = 'Go to Anywhere' })
  vim.keymap.set('', 'f', function()
    hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
  end, { remap = true })
  vim.keymap.set('', 'F', function()
    hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
  end, { remap = true })
  vim.keymap.set('', 't', function()
    hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true, hint_offset = -1 })
  end, { remap = true })
  vim.keymap.set('', 'T', function()
    hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true, hint_offset = 1 })
  end, { remap = true })
end

function keysRegisterEasyAlign()
  vim.keymap.set('n', 'ga', '<Plug>(EasyAlign)', { desc = 'Easy Align' })
  vim.keymap.set('v', 'ga', '<Plug>(EasyAlign)', { desc = 'Easy Align' })
end

function keysRegisterGit(gs)
  local wk = require('which-key')
  local gitlinker = require('gitlinker')

  wk.add({
    mode = 'n',

    { '<space>v',  group = 'Git' },
    { '<space>vs', gs.stage_hunk,      desc = 'Stage Hunk' },
    { '<space>vS', gs.stage_buffer,    desc = 'Stage Buffer' },
    { '<space>vr', gs.reset_hunk,      desc = 'Reset Hunk' },
    { '<space>vR', gs.reset_buffer,    desc = 'Reset Buffer' },
    { '<space>vu', gs.undo_stage_hunk, desc = 'Undo Stage Hunk' },
    { '<space>vp', gs.preview_hunk,    desc = 'Preview Hunk' },
    {
      '<space>vB',
      function()
        gs.blame_line({ full = true })
      end,
      desc = 'Show Blame Line',
    },
    -- Github: https://github.com/tpope/vim-fugitive
    { '<space>vd', '<cmd>Gdiffsplit<cr>', desc = 'Show diff' },
    { '<space>vb', '<cmd>Git blame<cr>',  desc = 'Show blame' },
    -- Github: https://github.com/ruifm/gitlinker.nvim
    {
      '<space>vo',
      function()
        gitlinker.get_buf_range_url('n', { action_callback = gitlinker.actions.open_in_browser })
      end,
      desc = 'Open Line in Browser',
    },
    {
      '<space>vO',
      function()
        gitlinker.get_repo_url({ action_callback = gitlinker.actions.open_in_browser })
      end,
      desc = 'Open Home in Browser',
    },

    -- Yank
    { '<space>y',  group = 'Yank' },
    {
      '<space>yv',
      function()
        gitlinker.get_buf_range_url('n')
      end,
      desc = 'Copy Github Line Link',
    },
    { '<space>yV', gitlinker.get_repo_url,              desc = 'Copy github home link' },
    { '<space>yp', "<cmd>let @+ = expand('%:~:.')<cr>", desc = 'Copy relative path' },
    { '<space>yP', "<cmd>let @+ = expand('%:p')<cr>",   desc = 'Copy abs path' },

    -- Toggle
    { '<space>t',  group = 'Toggle' },
    { '<space>tb', gs.toggle_current_line_blame,        desc = 'Toggle line blame' },
    { '<space>td', gs.toggle_deleted,                   desc = 'Toggle deleted' },
  })

  wk.add({
    mode = 'v',
    { '<space>y', group = 'Yank' },
    {
      '<space>yv',
      function()
        gitlinker.get_buf_range_url('v')
      end,
      desc = 'Copy Github Line Link',
    },

    { '<space>v', group = 'Git' },
    {
      '<space>vr',
      function()
        gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end,
      desc = 'Reset Hunk',
    },
    {
      '<space>vs',
      function()
        gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end,
      desc = 'Stage Hunk',
    },
    {
      '<space>vo',
      function()
        gitlinker.get_buf_range_url('v', { action_callback = gitlinker.actions.open_in_browser })
      end,
      desc = 'Open Line in Browser',
    },
  })
end

function keysRegisterTSMove()
  local wk = require('which-key')
  local ts_repeat_move = require('nvim-treesitter.textobjects.repeatable_move')
  local gs = require('gitsigns')
  local url = require('urlview.jump')
  local grapple = require('grapple')

  local next_hunk_repeat, prev_hunk_repeat = ts_repeat_move.make_repeatable_move_pair(gs.next_hunk, gs.prev_hunk)
  local next_url_repeat, prev_url_repeat = ts_repeat_move.make_repeatable_move_pair(url.next_url, url.prev_url)
  local next_diagnostic_repeat, prev_diagnostic_repeat =
      ts_repeat_move.make_repeatable_move_pair(vim.diagnostic.goto_next, vim.diagnostic.goto_prev)
  local next_mark_repeat, prev_mark_repeat =
      ts_repeat_move.make_repeatable_move_pair(grapple.cycle_forward, grapple.cycle_backward)

  wk.add({
    mode = { 'n', 'x', 'o' },

    { ';',  ts_repeat_move.repeat_last_move_next,     desc = 'Repeat Last Move Next' },
    { ',',  ts_repeat_move.repeat_last_move_previous, desc = 'Repeat Last Move Previous' },

    { '[',  group = 'Move Prev' },
    { '[v', prev_hunk_repeat,                         desc = 'Goto prev hunk' },
    { '[u', prev_url_repeat,                          desc = 'Goto prev URL' },
    { '[d', prev_diagnostic_repeat,                   desc = 'Goto prev Diagnostic' },
    { '[m', prev_mark_repeat,                         desc = 'Goto prev Mark' },

    { ']',  group = 'Move Next' },
    { ']v', next_hunk_repeat,                         desc = 'Goto next hunk' },
    { ']u', next_url_repeat,                          desc = 'Goto next URL' },
    { ']d', next_diagnostic_repeat,                   desc = 'Goto next Diagnostic' },
    { ']m', next_mark_repeat,                         desc = 'Goto next Mark' },
  })
end

function keysPluginSpectre()
  return {
    ['tab'] = {
      map = '<Tab>',
      cmd = "<cmd>lua require('spectre').tab()<cr>",
      desc = 'next query',
    },
    ['shift-tab'] = {
      map = '<S-Tab>',
      cmd = "<cmd>lua require('spectre').tab_shift()<cr>",
      desc = 'previous query',
    },
    ['toggle_line'] = {
      map = 'dd',
      cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
      desc = 'toggle item',
    },
    ['enter_file'] = {
      map = '<cr>',
      cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
      desc = 'open file',
    },
    ['send_to_qf'] = {
      map = '<space>rq',
      cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
      desc = 'send all items to quickfix',
    },
    ['replace_cmd'] = {
      map = '<space>ri',
      cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
      desc = 'input replace command',
    },
    ['show_option_menu'] = {
      map = '<space>rm',
      cmd = "<cmd>lua require('spectre').show_options()<CR>",
      desc = 'show options',
    },
    ['run_current_replace'] = {
      map = '<space>rc',
      cmd = "<cmd>lua require('spectre.actions').run_current_replace()<CR>",
      desc = 'replace current line',
    },
    ['run_replace'] = {
      map = '<space>ra',
      cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
      desc = 'replace all',
    },
    ['change_view_mode'] = {
      map = '<space>rv',
      cmd = "<cmd>lua require('spectre').change_view()<CR>",
      desc = 'change result view mode',
    },
    ['change_replace_sed'] = {
      map = 'trs',
      cmd = "<cmd>lua require('spectre').change_engine_replace('sed')<CR>",
      desc = 'use sed to replace',
    },
    ['change_replace_oxi'] = {
      map = 'tro',
      cmd = "<cmd>lua require('spectre').change_engine_replace('oxi')<CR>",
      desc = 'use oxi to replace',
    },
    ['toggle_live_update'] = {
      map = 'tu',
      cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>",
      desc = 'update when vim writes to file',
    },
    ['toggle_ignore_case'] = {
      map = 'ti',
      cmd = "<cmd>lua require('spectre').change_options('ignore-case')<CR>",
      desc = 'toggle ignore case',
    },
    ['toggle_ignore_hidden'] = {
      map = 'th',
      cmd = "<cmd>lua require('spectre').change_options('hidden')<CR>",
      desc = 'toggle search hidden',
    },
    ['resume_last_search'] = {
      map = '<space>rl',
      cmd = "<cmd>lua require('spectre').resume_last_search()<CR>",
      desc = 'repeat last search',
    },
  }
end

function keysPluginColortils()
  return {
    -- increment values
    increment = 'l',
    -- decrement values
    decrement = 'h',
    -- increment values with bigger steps
    increment_big = 'L',
    -- decrement values with bigger steps
    decrement_big = 'H',
    -- set values to the minimum
    min_value = '^',
    -- set values to the maximum
    max_value = '$',
    -- save the current color in the register specified above with the format specified above
    set_register_default_format = '<cr>',
    -- save the current color in the register specified above with a format you can choose
    set_register_cjoose_format = 'g<cr>',
    -- replace the color under the cursor with the current color in the format specified above
    replace_default_format = '<m-cr>',
    -- replace the color under the cursor with the current color in a format you can choose
    replace_choose_format = 'g<m-cr>',
    -- export the current color to a different tool
    export = 'E',
    -- set the value to a certain number (done by just entering numbers)
    set_value = 'c',
    -- toggle transparency
    transparency = 'T',
    -- choose the background (for transparent colors)
    choose_background = 'B',
  }
end

table.insert(plugins, {
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300

      keysRegisterBase()
      keysRegisterImprovements()
    end,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      -- triggers_blacklist = {
      --   n = { 'j', 'k' },
      -- },
    },
  },
})
