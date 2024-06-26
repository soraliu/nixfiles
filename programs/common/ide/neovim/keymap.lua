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

  wk.register({
    -- File Management
    ['<c-s>'] = { '<cmd>w<cr>', 'Save File' },
    ['<c-q>'] = { '<cmd>q<cr>', 'Quit' },

    -- Windows Management
    ['<leader>w'] = {
      name = 'Windows Management',
      h = { '<c-w>h', 'Focus on Left' },
      l = { '<c-w>l', 'Focus on Right' },
      j = { '<c-w>j', 'Focus on Bottom' },
      k = { '<c-w>k', 'Focus on Above' },
      r = { '<c-w>=', 'Restore window size' },
      z = { '<cmd>ZenMode<cr>', 'Toggle ZenMode' },
      ['['] = { '<cmd>vertical resize -10<cr>', 'Vertical Size -10' },
      [']'] = { '<cmd>vertical resize +10<cr>', 'Vertical Size +10' },
      ['-'] = { '<cmd>resize -10<cr>', 'Window Size -10' },
      ['+'] = { '<cmd>resize +10<cr>', 'Window Size +10' },
    },
  }, { mode = 'n' })
end

function keysRegisterImprovements()
  local wk = require('which-key')

  wk.register({
    ['<leader>s'] = {
      name = 'Show Pages/Search',
      -- Repo: goolord/alpha-nvim
      h = { '<cmd>Alpha<cr>', 'Show Home Page' },
      n = { '<cmd>Navbuddy<cr>', 'Show LSP Nav' },

      -- telescope luasnip
      s = { '<cmd>Telescope luasnip<cr>', 'Search luasnip' },

      -- telescope notify
      m = { '<cmd>Telescope notify<cr>', 'Search msg & notification' },

      -- Repo: soraliu/colortils.nvim
      c = { '<cmd>Colortils css list<cr>', 'Show Css Colors' },
    },
    ['<leader>e'] = {
      name = 'Code Edit',

      -- Repo: soraliu/vim-argwrap
      a = { '<cmd>ArgWrap<cr>', 'Args Wrap&Split' },
      -- Repo: AckslD/nvim-FeMaco.lua
      m = { '<cmd>FeMaco<cr>', 'Edit Markdown Codeblock' },
      -- Repo: soraliu/colortils.nvim
      c = { '<cmd>Colortils picker<cr>', 'Edit Color' },
    },
    ['<leader>r'] = {
      name = 'Replacement',

      -- Repo: nvim-pack/nvim-spectre
      ['o'] = { '<cmd>lua require("spectre").toggle()<CR>', 'Open spectre replacement' },
      ['w'] = { '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', 'Replace word on current file' },
      ['s'] = { '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', 'Replace current word' },
    },
    ['<leader>t'] = {
      name = 'Toggle',

      -- Repo: levouh/tint.nvim
      ['i'] = { '<cmd>lua require("tint").toggle()<cr>', 'Toggle dim inactive windown' },

      -- Repo: hedyhli/outline.nvim
      ['o'] = { '<cmd>Outline<CR>', 'Toggle outline' },
    },
  }, { mode = 'n' })

  wk.register({
    ['<leader>r'] = {

      -- Repo: nvim-pack/nvim-spectre
      ['o'] = { '<esc><cmd>lua require("spectre").open_visual()<CR>', 'Open spectre replacement' },
    },
  }, { mode = 'v' })
end

function keysRegisterSearch()
  local wk = require('which-key')
  local builtin = require('telescope.builtin')
  local ap = require('actions-preview')

  wk.register({
    ['<leader>f'] = {
      name = 'Fuzzy Search', -- optional group name

      -- Editor
      p = { '<cmd>Telescope<cr>', 'Telescope Home' },
      l = {
        function()
          builtin.git_files({ show_untracked = true })
        end,
        'Find Files',
      },
      o = {
        function()
          builtin.oldfiles({ cwd_only = true })
        end,
        'Find Recent Files',
      },
      b = { builtin.buffers, 'Find Opened Buffers' },
      w = { builtin.grep_string, 'Grep Cursor Word' },
      k = { builtin.keymaps, 'Find Keymaps' },
      h = { builtin.help_tags, 'Find Helps' },
      x = { builtin.commands, 'Find Commands' },
      m = { '<cmd>Telescope grapple tags<cr>', 'Find Grapple Tags' },
      [','] = { builtin.resume, 'Resume Last Search' },
      s = { '<cmd>Telescope egrepify<cr>', 'Grep String' },

      -- LSP
      d = { builtin.diagnostics, 'LSP Diagnostics' },
      r = { builtin.lsp_references, 'LSP References' },
      i = { builtin.lsp_implementations, 'LSP Implementations' },
      a = { ap.code_actions, 'LSP Actions' },

      -- Git
      v = { builtin.git_status, 'Git Status' },

      -- Todo
      -- Repo: folke/todo-comments.nvim
      n = { '<cmd>TodoTelescope<cr>', 'Find Todos' },

      -- Undo
      u = { '<cmd>Telescope undo<cr>', 'Undo History' },

      -- Yank
      y = { '<cmd>Telescope neoclip<cr>', 'Yank History' },

      -- Emoji
      e = { builtin.symbols, 'Emoji' },

      -- Font Emoji
      f = { '<cmd>Telescope glyph<cr>', 'Font Emoji' },

      -- URL
      j = { '<cmd>UrlView<cr>', 'Jump to a Url' },

      -- Lazy
      z = { '<cmd>Telescope lazy<cr>', 'lazy.nvim' },

      -- file-browser
      g = {
        function()
          require('telescope').extensions.file_browser.file_browser({ hidden = true, depth = 2 })
        end,
        'File Browser',
      },
      ['.'] = {
        function()
          require('telescope').extensions.file_browser.file_browser({
            hidden = true,
            depth = 2,
            path = '%:p:h',
            select_buffer = true,
          })
        end,
        'File Browser',
      },
    },
  }, { mode = 'n' })

  wk.register({
    -- :h actions-preview.nvim-configuration
    ['<leader>fa'] = { ap.code_actions, 'LSP Actions' },
  }, { mode = 'v' })
end

function keysRegisterMarks()
  local wk = require('which-key')

  wk.register({
    ['m'] = {
      name = 'Mark',
      a = { '<cmd>Grapple toggle<cr>', 'Grapple toggle tag' },
      l = { '<cmd>Grapple toggle_tags<cr>', 'Grapple open tags window' },
      ['1'] = { '<cmd>Grapple select index=1<cr>', 'Select first tag' },
      ['2'] = { '<cmd>Grapple select index=2<cr>', 'Select second tag' },
      ['3'] = { '<cmd>Grapple select index=3<cr>', 'Select third tag' },
      ['4'] = { '<cmd>Grapple select index=4<cr>', 'Select fourth tag' },
      ['5'] = { '<cmd>Grapple select index=5<cr>', 'Select fifth tag' },
      ['6'] = { '<cmd>Grapple select index=6<cr>', 'Select sixth tag' },
      ['7'] = { '<cmd>Grapple select index=7<cr>', 'Select seventh tag' },
      ['8'] = { '<cmd>Grapple select index=8<cr>', 'Select eighth tag' },
      ['9'] = { '<cmd>Grapple select index=9<cr>', 'Select ninth tag' },
    },
  }, { mode = { 'n' } })
end

function keysRegisterChatGPT()
  local wk = require('which-key')

  wk.register({
    ['<leader>c'] = {
      name = 'ChatGPT',
      c = { '<cmd>ChatGPT<CR>', 'ChatGPT' },
      e = { '<cmd>ChatGPTEditWithInstruction<CR>', 'Edit with instruction' },
      g = { '<cmd>ChatGPTRun grammar_correction<CR>', 'Grammar Correction' },
      t = { '<cmd>ChatGPTRun translate<CR>', 'Translate' },
      k = { '<cmd>ChatGPTRun keywords<CR>', 'Keywords' },
      d = { '<cmd>ChatGPTRun docstring<CR>', 'Docstring' },
      a = { '<cmd>ChatGPTRun add_tests<CR>', 'Add Tests' },
      o = { '<cmd>ChatGPTRun optimize_code<CR>', 'Optimize Code' },
      s = { '<cmd>ChatGPTRun summarize<CR>', 'Summarize' },
      f = { '<cmd>ChatGPTRun fix_bugs<CR>', 'Fix Bugs' },
      x = { '<cmd>ChatGPTRun explain_code<CR>', 'Explain Code' },
      r = { '<cmd>ChatGPTRun roxygen_edit<CR>', 'Roxygen Edit' },
      l = { '<cmd>ChatGPTRun code_readability_analysis<CR>', 'Code Readability Analysis' },
    },
  }, { mode = { 'n', 'v' } })
end

function keysRegisterFileTree()
  local wk = require('which-key')

  -- mappings
  wk.register({
    ['<leader>w'] = {
      name = 'Windows Management',

      a = { '<cmd>NvimTreeFindFile<cr>', 'Find File' },
      e = { '<cmd>NvimTreeToggle<cr>', 'Toggle Nvim Tree' },
    },
  }, { mode = 'n' })

  local function on_attach(bufnr)
    local api = require('nvim-tree.api')

    local function opts(desc)
      return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end
    local function removeMap(lhs)
      vim.keymap.del('n', lhs, { buffer = bufnr })
    end

    -- default mappings
    api.config.mappings.default_on_attach(bufnr)

    -- remove all bookmark shortcut
    removeMap('m')
    removeMap('M')
    removeMap('bd')
    removeMap('bt')
    removeMap('bmv')

    -- custom mappings
    vim.keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
    vim.keymap.set('n', 'p', api.node.navigate.parent, opts('Parent Directory'))
    vim.keymap.set('n', 'P', api.fs.paste, opts('Paste'))
    vim.keymap.set('n', 'm', api.fs.rename_full, opts('Rename: Full Path'))
  end

  return on_attach
end

function keysRegisterLSP(opts)
  local wk = require('which-key')
  local buffer = opts.buffer

  wk.register({
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    -- See `:help vim.diagnostic.*` for documentation on any of the below functions
    ['K'] = { vim.lsp.buf.hover, 'Show Hover Doc' },
    ['<c-]>'] = { vim.lsp.buf.definition, 'Go Definition' },

    ['<leader>g'] = {
      name = 'Go Somewhere',
      o = { vim.lsp.buf.type_definition, 'Go Type Definition' },
      d = { vim.lsp.buf.declaration, 'Go Declaration' },
    },

    ['<leader>a'] = {
      name = 'Action',
      r = { vim.lsp.buf.rename, 'LSP Rename' },
      f = {
        function()
          vim.lsp.buf.format({ async = true })
        end,
        'LSP Format',
      },
    },
  }, { mode = 'n', buffer = buffer })

  -- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
  -- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
  -- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
  -- vim.keymap.set('n', '<space>wl', function()
  --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  -- end, opts)
end

function keysRegisterBuffer()
  local wk = require('which-key')

  wk.register({
    ['<c-w>'] = { '<cmd>bp<bar>sp<bar>bn<bar>bd<cr>', 'Close Buffer' },

    ['<leader>'] = {
      ['1'] = { '<cmd>BufferLineGoToBuffer 1<cr>', 'Go to Buffer 1' },
      ['2'] = { '<cmd>BufferLineGoToBuffer 2<cr>', 'Go to Buffer 2' },
      ['3'] = { '<cmd>BufferLineGoToBuffer 3<cr>', 'Go to Buffer 3' },
      ['4'] = { '<cmd>BufferLineGoToBuffer 4<cr>', 'Go to Buffer 4' },
      ['5'] = { '<cmd>BufferLineGoToBuffer 5<cr>', 'Go to Buffer 5' },
      ['6'] = { '<cmd>BufferLineGoToBuffer 6<cr>', 'Go to Buffer 6' },
      ['7'] = { '<cmd>BufferLineGoToBuffer 7<cr>', 'Go to Buffer 7' },
      ['8'] = { '<cmd>BufferLineGoToBuffer 8<cr>', 'Go to Buffer 8' },
      ['9'] = { '<cmd>BufferLineGoToBuffer 9<cr>', 'Go to Buffer 9' },
      ['$'] = { '<cmd>BufferLineGoToBuffer -1<cr>', 'Go to Buffer -1' },

      ['['] = { '<cmd>BufferLineCyclePrev<cr>', 'Prev Buffer' },
      [']'] = { '<cmd>BufferLineCycleNext<cr>', 'Next Buffer' },
    },

    ['<leader>b'] = {
      name = 'Buffer Management',

      ['['] = { '<cmd>BufferLineMovePrev<cr>', 'Move to Prev' },
      [']'] = { '<cmd>BufferLineMoveNext<cr>', 'Move to Next' },
      p = { '<cmd>BufferLinePick<cr>', 'Pick a Buffer' },
      o = { '<cmd>BufferLineCloseOthers<cr>', 'Close Other Buffers' },
    },
  }, { mode = 'n' })
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

function keysRegisterGomove()
  local wk = require('which-key')

  wk.register({
    ['<leader>d'] = {
      name = 'Duplicate',

      h = { '<Plug>GoNSDLeft', 'Duplicate Left' },
      j = { '<Plug>GoNSDDown', 'Duplicate Down' },
      k = { '<Plug>GoNSDUp', 'Duplicate Up' },
      l = { '<Plug>GoNSDRight', 'Duplicate Right' },
    },

    ['<C-h>'] = { '<Plug>GoNSMLeft', 'Move Left' },
    ['<C-j>'] = { '<Plug>GoNSMDown', 'Move Down' },
    ['<C-k>'] = { '<Plug>GoNSMUp', 'Move Up' },
    ['<C-l>'] = { '<Plug>GoNSMRight', 'Move Right' },
  }, { mode = 'n' })

  wk.register({
    ['<leader>d'] = {
      name = 'Duplicate',

      h = { '<Plug>GoVSDLeft', 'Duplicate Left' },
      j = { '<Plug>GoVSDDown', 'Duplicate Down' },
      k = { '<Plug>GoVSDUp', 'Duplicate Up' },
      l = { '<Plug>GoVSDRight', 'Duplicate Right' },
    },

    ['<C-h>'] = { '<Plug>GoVSMLeft', 'Move Left' },
    ['<C-j>'] = { '<Plug>GoVSMDown', 'Move Down' },
    ['<C-k>'] = { '<Plug>GoVSMUp', 'Move Up' },
    ['<C-l>'] = { '<Plug>GoVSMRight', 'Move Right' },
  }, { mode = 'x' })
end

function keysRegisterGit(gs)
  local wk = require('which-key')
  local gitlinker = require('gitlinker')

  wk.register({
    ['<leader>v'] = {
      name = 'Git',
      s = { gs.stage_hunk, 'Stage Hunk' },
      S = { gs.stage_buffer, 'Stage Buffer' },
      r = { gs.reset_hunk, 'Reset Hunk' },
      R = { gs.reset_buffer, 'Reset Buffer' },
      u = { gs.undo_stage_hunk, 'Undo Stage Hunk' },
      p = { gs.preview_hunk, 'Preview Hunk' },
      B = {
        function()
          gs.blame_line({ full = true })
        end,
        'Show Blame Line',
      },

      -- Github: https://github.com/tpope/vim-fugitive
      d = { '<cmd>Gdiffsplit<cr>', 'Show diff' },
      b = { '<cmd>Git blame<cr>', 'Show blame' },

      -- Github: https://github.com/ruifm/gitlinker.nvim
      o = {
        function()
          gitlinker.get_buf_range_url('n', { action_callback = gitlinker.actions.open_in_browser })
        end,
        'Open Line in Browser',
      },
      O = {
        function()
          gitlinker.get_repo_url({ action_callback = gitlinker.actions.open_in_browser })
        end,
        'Open Home in Browser',
      },
    },
    ['<leader>y'] = {
      name = 'Yank',
      v = {
        function()
          gitlinker.get_buf_range_url('n')
        end,
        'Copy Github Line Link',
      },
      V = { gitlinker.get_repo_url, 'Copy github home link' },
      p = { "<cmd>let @+ = expand('%:~:.')<cr>", 'Copy relative path' },
      P = { "<cmd>let @+ = expand('%:p')<cr>", 'Copy abs path' },
    },
    ['<leader>t'] = {
      name = 'Toggle',
      ['b'] = { gs.toggle_current_line_blame, 'Toggle line blame' },
      ['d'] = { gs.toggle_deleted, 'Toggle deleted' },
    },
  }, { mode = 'n' })

  wk.register({
    ['<leader>y'] = {
      name = 'Yank',
      v = {
        function()
          gitlinker.get_buf_range_url('v')
        end,
        'Copy Github Line Link',
      },
    },
    ['<leader>v'] = {
      name = 'Git',
      r = {
        function()
          gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
        end,
        'Reset Hunk',
      },
      s = {
        function()
          gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
        end,
        'Stage Hunk',
      },
      o = {
        function()
          gitlinker.get_buf_range_url('v', { action_callback = gitlinker.actions.open_in_browser })
        end,
        'Open Line in Browser',
      },
    },
  }, { mode = 'v' })
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

  wk.register({
    [';'] = { ts_repeat_move.repeat_last_move_next, 'Repeat Last Move Next' },
    [','] = { ts_repeat_move.repeat_last_move_previous, 'Repeat Last Move Previous' },

    ['['] = {
      name = 'Move Prev',
      ['v'] = { prev_hunk_repeat, 'Goto prev hunk' },
      ['u'] = { prev_url_repeat, 'Goto prev URL' },
      ['d'] = { prev_diagnostic_repeat, 'Goto prev Diagnostic' },
      ['m'] = { prev_mark_repeat, 'Goto prev Mark' },
    },
    [']'] = {
      name = 'Move Next',
      ['v'] = { next_hunk_repeat, 'Goto next hunk' },
      ['u'] = { next_url_repeat, 'Goto next URL' },
      ['d'] = { next_diagnostic_repeat, 'Goto next Diagnostic' },
      ['m'] = { next_mark_repeat, 'Goto next Mark' },
    },
  }, { mode = { 'n', 'x', 'o' } })
end

function keysPluginCmp()
  local cmp = require('cmp')
  local luasnip = require('luasnip')

  return {
    ['<C-l>'] = cmp.mapping(function(fallback)
      if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<C-h>'] = cmp.mapping(function(fallback)
      if luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<C-j>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
        -- elseif luasnip.jumpable(1) then
        --   luasnip.jump(1)
      else
        cmp.complete()
      end
    end, { 'i', 's' }),
    ['<C-k>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
        -- elseif luasnip.jumpable(-1) then
        --   luasnip.jump(-1)
      else
        cmp.complete()
      end
    end, { 'i', 's' }),
    -- Reset <c-p> & <c-n>
    ['<C-n>'] = cmp.mapping(function(fallback)
      fallback()
    end, { 'i', 's' }),
    ['<C-p>'] = cmp.mapping(function(fallback)
      fallback()
    end, { 'i', 's' }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-d>'] = cmp.mapping.scroll_docs(4),
    ['<C-e>'] = cmp.mapping.abort(),
    -- ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    }),
  }
end

function keysPluginComment()
  vim.keymap.set('x', '<c-_>', '<Plug>(comment_toggle_linewise_visual)')
  vim.keymap.set('x', '<c-\\>', '<Plug>(comment_toggle_blockwise_visual)')

  return {
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
  }
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
      map = '<leader>rq',
      cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
      desc = 'send all items to quickfix',
    },
    ['replace_cmd'] = {
      map = '<leader>ri',
      cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
      desc = 'input replace command',
    },
    ['show_option_menu'] = {
      map = '<leader>rm',
      cmd = "<cmd>lua require('spectre').show_options()<CR>",
      desc = 'show options',
    },
    ['run_current_replace'] = {
      map = '<leader>rc',
      cmd = "<cmd>lua require('spectre.actions').run_current_replace()<CR>",
      desc = 'replace current line',
    },
    ['run_replace'] = {
      map = '<leader>ra',
      cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
      desc = 'replace all',
    },
    ['change_view_mode'] = {
      map = '<leader>rv',
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
      map = '<leader>rl',
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
      triggers_blacklist = {
        n = { 'j', 'k' },
      },
    },
  },
})
