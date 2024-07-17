-- -------------------------------------------------------------------------------------------------------------------------------
-- LSP Mason
-- -------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    'williamboman/mason.nvim',
    opts = {
      ui = {
        icons = {
          package_installed = '✓',
          package_pending = '➜',
          package_uninstalled = '✗',
        },
      },
    },
  },
  {
    'jay-babu/mason-null-ls.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      ensure_installed = {
        -- Opt to list sources here, when available in mason.
        'prettierd',
        'eslint_d',
        'revive',
      },
      automatic_installation = false,
      handlers = {},
    },
  },
  {
    'williamboman/mason-lspconfig.nvim',
    opts = {
      ensure_installed = {
        'cmake',                 -- Makefile, configure.ac
        'bashls',                -- bash
        'jsonls',                -- json
        'gopls',                 -- golang
        'tsserver',              -- js, jsx, ts, tsx
        'rnix',                  -- nix
        'yamlls',                -- yaml
        'lua_ls',                -- lua
        'emmet_language_server', -- css emmet
      },
    },
    init = function()
      require('mason-lspconfig').setup_handlers({
        -- The first entry (without a key) will be the default handler
        -- and will be called for each installed server that doesn't have
        -- a dedicated handler.
        function(server_name) -- default handler (optional)
          require('lspconfig')[server_name].setup({})
        end,

        -- To support coq_nvim
        -- local coq = require "coq"
        -- function (server_name) -- default handler (optional)
        --     require("lspconfig")[server_name].setup(coq.lsp_ensure_capabilities {})
        -- end,

        -- Next, you can provide a dedicated handler for specific servers.
        -- For example, a handler override for the `rust_analyzer`:
        -- ["rust_analyzer"] = function ()
        --     require("rust-tools").setup {}
        -- end
      })
    end,
  },
})

-- -------------------------------------------------------------------------------------------------------------------------------
-- LSP CMP
-- -------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  { 'hrsh7th/cmp-cmdline' },         -- cmdline
  { 'dmitmel/cmp-cmdline-history' }, -- cmdline history
  {
    'hrsh7th/nvim-cmp',
    lazy = false,
    config = function()
      -- Set up nvim-cmp.
      local cmp_status_ok, cmp = pcall(require, 'cmp')
      if not cmp_status_ok then
        return
      end

      -- add `()` after the choosed function in lsp completion
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

      -- luasnip
      local snip_status_ok, luasnip = pcall(require, 'luasnip')
      if not snip_status_ok then
        return
      end
      require('luasnip/loaders/from_vscode').lazy_load()

      -- adds vscode-like pictograms(icons) to neovim built-in lsp
      local lspkind = require('lspkind')
      local cmp_format = lspkind.cmp_format({
        mode = 'symbol_text', -- show only symbol annotations
        maxwidth = 50,        -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
        -- can also be a function to dynamically calculate max width such as
        -- maxwidth = function() return math.floor(0.45 * vim.o.columns) end,
        ellipsis_char = '...',    -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
        show_labelDetails = true, -- show labelDetails in menu. Disabled by default

        -- symbol map
        symbol_map = {
          Copilot = '',
        },

        -- The function below will be called before any actual modifications from lspkind
        -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
        menu = {
          buffer = '[Buffer]',
          rg = '[Ripgrep]',
          nvim_lsp = '[LSP]',
          nvim_lua = '[Lua]',
          path = '[Path]',
          luasnip = '[Luasnip]',
          spell = '[Spell]',
          look = '[Dict]',
          cmdline = '[CMD]',
          cmdline_history = '[CMD History]',
          copilot = '[Copilot]',
        },
        before = function(entry, vim_item)
          return vim_item
        end,
      })

      cmp.setup({
        snippet = {
          -- REQUIRED - you must specify a snippet engine
          expand = function(args)
            -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
            -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
            luasnip.lsp_expand(args.body) -- For `luasnip` users.
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
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
        }),
        formatting = {
          format = cmp_format,
        },
        sources = cmp.config.sources({
          { name = 'copilot' },
          { name = 'nvim_lsp' },
          { name = 'nvim_lua' },
          { name = 'path' },
          {
            name = 'buffer',
            option = {
              get_bufnrs = function()
                return vim.api.nvim_list_bufs()
              end,
            },
          },
          {
            name = 'rg',
            keyword_length = 2,
          },
          -- { name = 'vsnip' }, -- For vsnip users.
          -- { name = 'ultisnips' }, -- For ultisnips users.
          -- { name = 'snippy' }, -- For snippy users.
          { name = 'luasnip' }, -- For luasnip users.
          {
            name = 'look',
            keyword_length = 2,
            option = {
              convert_case = true,
              loud = true,
              --dict = '/usr/share/dict/words'
            },
          },
          {
            name = 'spell',
            option = {
              keep_all_entries = false,
              enable_in_context = function()
                return true
              end,
            },
          },
        }),
      })

      cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' },
          { name = 'cmdline_history' },
        },
        formatting = {
          format = cmp_format,
        },
      })

      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' },
          { name = 'cmdline_history' },
          {
            name = 'cmdline',
            option = {
              ignore_cmds = { 'Man', '!' },
            },
          },
        }),
        formatting = {
          format = cmp_format,
        },
      })
    end,
  },
  { 'hrsh7th/cmp-nvim-lsp',     lazy = true }, -- nvim lsp
  { 'hrsh7th/cmp-buffer',       lazy = true }, -- words from opened buffers
  { 'lukas-reineke/cmp-rg',     lazy = true }, -- fuzzy search
  { 'hrsh7th/cmp-path',         lazy = true }, -- paths
  { 'windwp/nvim-autopairs',    lazy = true }, -- insert `(` after select function or method item
  { 'onsails/lspkind-nvim',     lazy = true }, -- show icons
  { 'octaltree/cmp-look',       lazy = true }, -- completing words in English
  { 'saadparwaiz1/cmp_luasnip', lazy = true }, -- cmp adapter of luasnip
})

-- -------------------------------------------------------------------------------------------------------------------------------
-- Native LSP
-- -------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    config = function()
      local lspconfig = require('lspconfig')

      -- Use LspAttach autocommand to only map the following keys
      -- after the language server attaches to the current buffer
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
          -- Enable completion triggered by <c-x><c-o>
          vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

          -- Register keymaps
          local wk = require('which-key')
          local buffer = ev.buf

          wk.add({
            mode = 'n',
            buffer = buffer,
            -- See `:help vim.lsp.*` for documentation on any of the below functions
            -- See `:help vim.diagnostic.*` for documentation on any of the below functions
            { 'K',         vim.lsp.buf.hover,           desc = 'Show Hover Doc' },
            { '<c-]>',     vim.lsp.buf.definition,      desc = 'Go Definition' },

            { '<space>g',  group = 'Go Somewhere' },
            { '<space>go', vim.lsp.buf.type_definition, desc = 'Go Type Definition' },
            { '<space>gd', vim.lsp.buf.declaration,     desc = 'Go Declaration' },

            { '<space>a',  group = 'Action' },
            { '<space>ar', vim.lsp.buf.rename,          desc = 'LSP Rename' },
            {
              '<space>af',
              function()
                vim.lsp.buf.format({ async = true })
              end,
              desc = 'LSP Format',
            },
          })

          -- TODO: to support auto show function signature
        end,
      })

      -- Lua
      lspconfig.lua_ls.setup({
        on_init = function(client)
          local path = client.workspace_folders[1].name
          if not vim.loop.fs_stat(path .. '/.luarc.json') and not vim.loop.fs_stat(path .. '/.luarc.jsonc') then
            client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
              Lua = {
                runtime = {
                  -- Tell the language server which version of Lua you're using
                  -- (most likely LuaJIT in the case of Neovim)
                  version = 'LuaJIT',
                },
                -- Make the server aware of Neovim runtime files
                workspace = {
                  checkThirdParty = false,
                  library = {
                    'vim.env.VIMRUNTIME',
                    -- Depending on the usage, you might want to add additional paths here.
                    -- E.g.: For using `vim.*` functions, add vim.env.VIMRUNTIME/lua.
                    'vim.env.VIMRUNTIME/lua',
                    '${3rd}/luv/library',
                    -- "${3rd}/busted/library",
                  },
                },
              },
            })
          end
          return true
        end,
      })

      -- swift
      lspconfig.sourcekit.setup({
        -- cmd = { "sourcekit-lsp" },
        -- root_dir = lspconfig.util.root_pattern(".git", "Package.swift", "compile_commands.json"),
        cmd = { 'xcrun', 'sourcekit-lsp' },
        filetypes = { 'swift', 'objective-c', 'objective-cpp' },
        root_dir = require('lspconfig').util.root_pattern('*.xcodeproj', '*.xcworkspace', '.git'),
        settings = {},
      })

      -- Golang
      lspconfig.gopls.setup({
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
            gofumpt = true,
          },
        },
      })

      -- CSS Emmet
      lspconfig.emmet_language_server.setup({
        filetypes = {
          'css',
          'eruby',
          'html',
          'javascript',
          'javascriptreact',
          'less',
          'sass',
          'scss',
          'pug',
          'typescriptreact',
        },
        -- Read more about this options in the [vscode docs](https://code.visualstudio.com/docs/editor/emmet#_emmet-configuration).
        -- **Note:** only the options listed in the table are supported.
        init_options = {
          ---@type table<string, string>
          includeLanguages = {},
          --- @type string[]
          excludeLanguages = {},
          --- @type string[]
          extensionsPath = {},
          --- @type table<string, any> [Emmet Docs](https://docs.emmet.io/customization/preferences/)
          preferences = {},
          --- @type boolean Defaults to `true`
          showAbbreviationSuggestions = true,
          --- @type "always" | "never" Defaults to `"always"`
          showExpandedAbbreviation = 'always',
          --- @type boolean Defaults to `false`
          showSuggestionsAsSnippets = false,
          --- @type table<string, any> [Emmet Docs](https://docs.emmet.io/customization/syntax-profiles/)
          syntaxProfiles = {},
          --- @type table<string, string> [Emmet Docs](https://docs.emmet.io/customization/snippets/#variables)
          variables = {},
        },
      })
    end,
    dependencies = {
      {
        -- Note: To make it work with Nix, should update the env of nvim-python to fix the issue of `can't find coq module`
        -- 1. run `:checkhealth provider`
        -- 2. edit the file of the value of `g:python3_host_prog`, e.g. `vi /nix/store/wb8ql9px3dn5j63k0nhnxlv1zzy0bcj4-neovim-0.9.4/bin/nvim-python3`
        -- 3. add `export PYTHONPATH="/root/.local/share/nvim/lazy/coq_nvim"` below the `unset PYTHONPATH`
        -- 4. force save the change

        -- uncomment the following codes to use `coq_nvim`
        -- "ms-jpq/coq_nvim",
        -- branch = "coq",
        -- dependencies = {
        --   "ms-jpq/coq.artifacts",
        --   branch = "artifacts"
        -- },
        -- config = function()
        -- end,
      },
    },
  },
  {
    'aznhe21/actions-preview.nvim',
    lazy = true,
    opts = {
      telescope = {
        sorting_strategy = 'ascending',
        layout_strategy = 'vertical',
        layout_config = {
          width = 0.8,
          height = 0.9,
          prompt_position = 'top',
          preview_cutoff = 20,
          preview_height = function(_, _, max_lines)
            return max_lines - 15
          end,
        },
      },
    },
  },
  { 'SmiteshP/nvim-navic',  lazy = true },
  { 'MunifTanjim/nui.nvim', lazy = true },
  {
    'SmiteshP/nvim-navbuddy',
    lazy = true,
    keys = {
      { '<space>sn', '<cmd>Navbuddy<cr>', mode = { 'n' }, desc = 'Show LSP Nav' },
    },
    config = function()
      local navbuddy = require('nvim-navbuddy')
      local nav_actions = require('nvim-navbuddy.actions')
      navbuddy.setup({
        lsp = { auto_attach = true },
        mappings = { ['?'] = nav_actions.help() },
      })
    end,
  },
})

-- -------------------------------------------------------------------------------------------------------------------------------
-- LSP for none-ls and specific languages
-- builtin sources: https://github.com/nvimtools/none-ls.nvim/blob/main/doc/BUILTINS.md
-- -------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    'nvimtools/none-ls.nvim',
    config = function()
      local null_ls = require('null-ls')
      local go_null_ls = require('go.null_ls')
      local augroup = vim.api.nvim_create_augroup('LspFormatting', {})

      local sources = {
        -- code actions
        go_null_ls.gotest_action(), -- LSP test code action for null-ls

        -- diagnostics
        --  TS, JS
        require('none-ls.diagnostics.eslint'),
        --  golang
        null_ls.builtins.diagnostics.revive,
        go_null_ls.gotest(),        -- LSP diagnostic source for null-ls
        go_null_ls.golangci_lint(), -- A async version of golangci-lint null-ls lint

        -- formatting
        --  TS, JS
        null_ls.builtins.formatting.prettierd,
        --  golang
        null_ls.builtins.formatting.goimports,
        null_ls.builtins.formatting.golines.with({
          extra_args = {
            '--max-len=80',
            '--base-formatter=gofumpt',
          },
        }),
        null_ls.builtins.formatting.stylua.with({
          extra_args = {
            '--indent-type=Spaces',
          },
        }),
      }

      null_ls.setup({
        sources = sources,
        debounce = 1000,
        default_timeout = 5000,
        on_attach = function(client, bufnr)
          if client.supports_method('textDocument/formatting') then
            vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
            vim.api.nvim_create_autocmd('BufWritePre', {
              group = augroup,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ async = false })
              end,
            })
          end
        end,
      })
    end,
  },

  { 'nvimtools/none-ls-extras.nvim',   lazy = true },
  { 'nvim-lua/plenary.nvim',           lazy = true },
  { 'ray-x/go.nvim',                   lazy = true },
  { 'ray-x/guihua.lua',                lazy = true },
  { 'neovim/nvim-lspconfig',           lazy = true },
  { 'nvim-treesitter/nvim-treesitter', lazy = true },
  {
    'ray-x/go.nvim',
    opts = {},
    event = { 'CmdlineEnter' },
    ft = { 'go', 'gomod' },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },
})
