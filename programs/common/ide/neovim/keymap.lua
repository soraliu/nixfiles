-- ------------------------------------------------------------------------------------------------------------------------------
-- keymaps
-- ------------------------------------------------------------------------------------------------------------------------------
function keysRegisterBase()
  local wk = require("which-key")

  -- set <leader> to <space>
  vim.g.mapleader = ' '
  -- shortcut of <ESC>
  vim.keymap.set('n', '<ESC>', ":noh<cr><ESC>", { silent = true, noremap = true })
  vim.keymap.set('i', 'jk', "<ESC>", { nowait = true })
  -- don't copy to clipboard
  vim.keymap.set('v', 's', '"_d', { noremap = true })
  -- movement when auto wrap
  vim.keymap.set('n', 'j', 'gj', { silent = true })
  vim.keymap.set('n', 'k', 'gk', { silent = true })
  vim.keymap.set('v', 'j', 'gj', { silent = true })
  vim.keymap.set('v', 'k', 'gk', { silent = true })
  -- do/undo
  -- vim.keymap.set('i', '<c-u>', '<c-o>u', { noremap = true })
  -- vim.keymap.set('i', '<c-r>', '<c-o><c-r>', { noremap = true })
  -- command mode
  vim.api.nvim_set_keymap('c', '<C-j>', '<C-n>', {})
  vim.api.nvim_set_keymap('c', '<C-k>', '<C-p>', {})


  wk.register({
    -- File Management
    ['<c-s>'] = { "<cmd>w<cr>", "Save File" },
    ['<c-q>'] = { "<cmd>q<cr>", "Quit" },

    -- Windows Management
    ['<leader>w'] = {
      name = "Windows Management",
      h = { "<c-w>h", "Focus on Left" },
      l = { "<c-w>l", "Focus on Right" },
      j = { "<c-w>j", "Focus on Bottom" },
      k = { "<c-w>k", "Focus on Above" },
      r = { "<c-w>=", "Restore window size" },
      ['['] = { "<cmd>vertical resize -10<cr>", "Window Size -10" },
      [']'] = { "<cmd>vertical resize +10<cr>", "Window Size +10" },
    },
  }, { mode = "n" })
end

function keysRegisterImprovements()
  local wk = require("which-key")

  wk.register({
    -- ['Q'] = {
    --   '<cmd>Bonly<cr>',                                                     'Delete buffers',
    -- },
    ['<leader>s'] = {
      name = "Show Pages",
      -- Repo: goolord/alpha-nvim
      h = { "<cmd>Alpha<cr>", "Show Home Page" },
      n = { "<cmd>Navbuddy<cr>", "Show LSP Nav" },
    },
    ['<leader>e'] = {
      name = "Code Edit",

      -- Repo: soraliu/vim-argwrap
      a = { "<cmd>ArgWrap<cr>", "Args Wrap&Split" },
      -- Repo: AckslD/nvim-FeMaco.lua
      m = { "<cmd>FeMaco<cr>", "Edit Markdown Codeblock" },
    },
  }, { mode = "n" })
end

function keysRegisterSearch()
  local wk = require("which-key")
  local builtin = require('telescope.builtin')
  local ap = require("actions-preview")

  wk.register({
    ["<leader>f"] = {
      name = "Fuzzy Search", -- optional group name

      -- Editor
      p = { "<cmd>Telescope<cr>", "Telescope Home" },
      l = { function() builtin.git_files({ show_untracked = true }) end, "Find Files" },
      o = { function() builtin.oldfiles({ cwd_only = true }) end, "Find Recent Files" },
      b = { builtin.buffers, "Find Opened Buffers" },
      w = { builtin.grep_string, "Grep Cursor Word" },
      k = { builtin.keymaps, "Find Keymaps" },
      h = { builtin.help_tags, "Find Helps" },
      m = { builtin.commands, "Find Commands" },
      [","] = { builtin.resume, "Resume Last Search" },
      s = { "<cmd>Telescope egrepify<cr>", "Grep String" },

      -- LSP
      d = { builtin.diagnostics, "LSP Diagnostics" },
      r = { builtin.lsp_references, "LSP References" },
      i = { builtin.lsp_implementations, "LSP Implementations" },
      a = { ap.code_actions, "LSP Actions" },

      -- Git
      v = { builtin.git_status, "Git Status" },

      -- Todo
      -- Repo: folke/todo-comments.nvim
      n = { "<cmd>TodoTelescope<cr>", "Find Todos" },

      -- Undo
      u = { "<cmd>Telescope undo<cr>", "Undo History" },

      -- Yank
      y = { "<cmd>Telescope neoclip<cr>", "Yank History" },

      e = { "<cmd>Telescope emoji<cr>", "Emoji" },

      f = { "<cmd>Telescope glyph<cr>", "Font Emoji" },
    },
  }, { mode = "n" })

  wk.register({
    -- :h actions-preview.nvim-configuration
    ["<leader>fa"] = { ap.code_actions, "LSP Actions" },
  }, { mode = "v" })
end

function keysRegisterTree()
  local wk = require("which-key")

  -- mappings
  wk.register({
    ["<leader>w"] = {
      name = "Windows Management",

      a = { "<cmd>NvimTreeFindFile<cr>", "Find File" },
      e = { "<cmd>NvimTreeToggle<cr>", "Toggle Nvim Tree" },
    },
  }, { mode = "n" })

  local function on_attach(bufnr)
    local api = require "nvim-tree.api"

    local function opts(desc)
      return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
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
  local wk = require("which-key")
  local buffer = opts.buffer

  wk.register({
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    -- See `:help vim.diagnostic.*` for documentation on any of the below functions
    ["K"] = { vim.lsp.buf.hover, "Show Hover Doc" },
    ["<c-]>"] = { vim.lsp.buf.definition, "Go Definition" },

    ["<leader>g"] = {
      name = "Go Somewhere",
      o = { vim.lsp.buf.type_definition, "Go Type Definition" },
      d = { vim.lsp.buf.declaration, "Go Declaration" },
      k = { vim.diagnostic.goto_prev, "Go Prev Diagnostic" },
      j = { vim.diagnostic.goto_next, "Go Next Diagnostic" },
    },

    ["<leader>a"] = {
      name = "Action",
      r = { vim.lsp.buf.rename, "LSP Rename" },
      f = { function() vim.lsp.buf.format({ async = true }) end, "LSP Format" },
    },
  }, { mode = "n", buffer = buffer })

  -- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
  -- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
  -- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
  -- vim.keymap.set('n', '<space>wl', function()
  --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  -- end, opts)
end

function keysRegisterBuffer()
  local wk = require("which-key")

  wk.register({
    ['<c-w>'] = { "<cmd>bp<bar>sp<bar>bn<bar>bd<cr>", "Close Buffer" },

    ["<leader>"] = {
      ["1"] = { "<cmd>BufferLineGoToBuffer 1<cr>", "Go to Buffer 1" },
      ["2"] = { "<cmd>BufferLineGoToBuffer 2<cr>", "Go to Buffer 2" },
      ["3"] = { "<cmd>BufferLineGoToBuffer 3<cr>", "Go to Buffer 3" },
      ["4"] = { "<cmd>BufferLineGoToBuffer 4<cr>", "Go to Buffer 4" },
      ["5"] = { "<cmd>BufferLineGoToBuffer 5<cr>", "Go to Buffer 5" },
      ["6"] = { "<cmd>BufferLineGoToBuffer 6<cr>", "Go to Buffer 6" },
      ["7"] = { "<cmd>BufferLineGoToBuffer 7<cr>", "Go to Buffer 7" },
      ["8"] = { "<cmd>BufferLineGoToBuffer 8<cr>", "Go to Buffer 8" },
      ["9"] = { "<cmd>BufferLineGoToBuffer 9<cr>", "Go to Buffer 9" },
      ["$"] = { "<cmd>BufferLineGoToBuffer -1<cr>", "Go to Buffer -1" },

      ['['] = { "<cmd>BufferLineCyclePrev<cr>", "Prev Buffer" },
      [']'] = { "<cmd>BufferLineCycleNext<cr>", "Next Buffer" },
    },


    ["<leader>b"] = {
      name = "Buffer Management",

      ["["] = { "<cmd>BufferLineMovePrev<cr>", "Move to Prev" },
      ["]"] = { "<cmd>BufferLineMoveNext<cr>", "Move to Next" },
      p = { "<cmd>BufferLinePick<cr>", "Pick a Buffer" },
      o = { "<cmd>BufferLineCloseOthers<cr>", "Close Other Buffers" },
    },
  }, { mode = "n" })
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

function keysRegisterGit(bufnr, gs)
  local wk = require('which-key')
  local gitlinker = require('gitlinker')

  -- Navigation
  vim.keymap.set('n', '[v', function()
    if vim.wo.diff then return '[v' end

    vim.schedule(function() gs.prev_hunk() end)
    return '<Ignore>'
  end, { buffer = bufnr, expr = true, desc = 'Prev Hunk' })
  vim.keymap.set('n', ']v', function()
    if vim.wo.diff then return ']v' end

    vim.schedule(function() gs.next_hunk() end)
    return '<Ignore>'
  end, { buffer = bufnr, expr = true, desc = 'Next Hunk' })

  wk.register({
    ['<leader>v'] = {
      name = 'Git',
      s = { gs.stage_hunk, 'Stage Hunk' },
      S = { gs.stage_buffer, 'Stage Buffer' },
      r = { gs.reset_hunk, 'Reset Hunk' },
      R = { gs.reset_buffer, 'Reset Buffer' },
      u = { gs.undo_stage_hunk, 'Undo Stage Hunk' },
      p = { gs.preview_hunk, 'Preview Hunk' },
      B = { function() gs.blame_line { full = true } end, 'Show Blame Line' },

      -- Github: https://github.com/tpope/vim-fugitive
      d = { '<cmd>Gdiffsplit<cr>', 'Show Diff' },
      b = { '<cmd>Git blame<cr>', 'Show Blame' },

      -- Github: https://github.com/ruifm/gitlinker.nvim
      o = { function() gitlinker.get_buf_range_url("n", { action_callback = gitlinker.actions.open_in_browser }) end, 'Open Line in Browser' },
      O = { function() gitlinker.get_repo_url({ action_callback = gitlinker.actions.open_in_browser }) end, 'Open Home in Browser' },
    },
    ['<leader>y'] = {
      name = 'Yank',
      v = { function() gitlinker.get_buf_range_url("n") end, 'Copy Github Line Link' },
      V = { gitlinker.get_repo_url, 'Copy Github Home Link' },
    },
    ['<leader>t'] = {
      name = "Toggle",
      ['b'] = { gs.toggle_current_line_blame, 'Toggle Line Blame' },
      ['d'] = { gs.toggle_deleted, 'Toggle Deleted' },
    },
  }, { mode = "n", buffer = bufnr })

  wk.register({
    ['<leader>y'] = {
      name = 'Yank',
      v = { function() gitlinker.get_buf_range_url("v") end, 'Copy Github Line Link' },
    },
    ['<leader>v'] = {
      name = 'Git',
      r = { function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, 'Reset Hunk' },
      s = { function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, 'Stage Hunk' },
      o = { function() gitlinker.get_buf_range_url("v", { action_callback = gitlinker.actions.open_in_browser }) end, 'Open Line in Browser' },
    },
  }, { mode = "v", buffer = bufnr })
end

function keysPluginCmp()
  local cmp = require("cmp")
  local luasnip = require("luasnip")

  return {
    ['<C-l>'] = cmp.mapping(function(fallback)
      if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ['<C-h>'] = cmp.mapping(function(fallback)
      if luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
    ['<C-j>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
        -- elseif luasnip.jumpable(1) then
        --   luasnip.jump(1)
      else
        cmp.complete()
      end
    end, { "i", "s" }),
    ['<C-k>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
        -- elseif luasnip.jumpable(-1) then
        --   luasnip.jump(-1)
      else
        cmp.complete()
      end
    end, { "i", "s" }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { "i", "s" }),
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-d>'] = cmp.mapping.scroll_docs(4),
    ['<C-e>'] = cmp.mapping.abort(),
    -- ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    ["<CR>"] = cmp.mapping.confirm({
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

function keysRegisterClearMem()
  local wk = require("which-key")

  wk.register({
  })
end

table.insert(plugins, {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
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
    }
  },
})
