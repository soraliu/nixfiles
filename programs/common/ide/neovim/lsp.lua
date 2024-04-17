-- -------------------------------------------------------------------------------------------------------------------------------
-- LSP
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
          keysRegisterLSP({ buffer = ev.buf })

          -- TODO: to support auto show function signature
        end,
      })

      local navbuddy = require('nvim-navbuddy')
      local nav_actions = require('nvim-navbuddy.actions')
      navbuddy.setup({
        mappings = { ['?'] = nav_actions.help() },
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
    end,
    dependencies = {
      {
        'williamboman/mason.nvim',
        config = function()
          require('mason').setup({
            ui = {
              icons = {
                package_installed = '✓',
                package_pending = '➜',
                package_uninstalled = '✗',
              },
            },
          })
        end,
      },
      {
        'williamboman/mason-lspconfig.nvim',
        config = function()
          require('mason-lspconfig').setup({
            ensure_installed = {
              'cmake', -- Makefile, configure.ac
              'bashls', -- bash
              'jsonls', -- json
              'gopls', -- golang
              'tsserver', -- js, jsx, ts, tsx
              'rnix', -- nix
              'yamlls', -- yaml
            },
          })
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
      {
        'hrsh7th/nvim-cmp',
        dependencies = {
          'hrsh7th/cmp-nvim-lsp',
          'hrsh7th/cmp-buffer', -- words from opened buffers
          'lukas-reineke/cmp-rg', -- fuzzy search
          'hrsh7th/cmp-path', -- paths
          'hrsh7th/cmp-cmdline', -- cmdline
          'dmitmel/cmp-cmdline-history', -- cmdline history
          'windwp/nvim-autopairs', -- insert `(` after select function or method item
          {
            'L3MON4D3/LuaSnip',
            version = 'v2.*', -- Replace <CurrentMajor> by the latest released major (first number of latest release)
            -- install jsregexp (optional!).
            build = 'make install_jsregexp',
          },
          'saadparwaiz1/cmp_luasnip', -- cmp adapter of luasnip
          'rafamadriz/friendly-snippets', -- include common used snippets
          'onsails/lspkind-nvim', -- show icons
          'octaltree/cmp-look', -- completing words in English
        },
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
            maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
            -- can also be a function to dynamically calculate max width such as
            -- maxwidth = function() return math.floor(0.45 * vim.o.columns) end,
            ellipsis_char = '...', -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
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
            mapping = cmp.mapping.preset.insert(keysPluginCmp()),
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
      {
        'aznhe21/actions-preview.nvim',
        config = function()
          require('actions-preview').setup({
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
          })
        end,
      },
      {
        'SmiteshP/nvim-navbuddy',
        dependencies = {
          'SmiteshP/nvim-navic',
          'MunifTanjim/nui.nvim',
        },
        opts = { lsp = { auto_attach = true } },
      },
    },
  },
})

-- -------------------------------------------------------------------------------------------------------------------------------
-- LSP for none-ls and specific languages
-- -------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    'nvimtools/none-ls.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'ray-x/go.nvim',
    },
    config = function()
      local null_ls = require('null-ls')
      local go_null_ls = require('go.null_ls')
      local augroup = vim.api.nvim_create_augroup('LspFormatting', {})

      local sources = {
        -- code actions
        go_null_ls.gotest_action(), -- LSP test code action for null-ls

        -- diagnostics
        null_ls.builtins.diagnostics.revive,
        go_null_ls.gotest(), -- LSP diagnostic source for null-ls
        go_null_ls.golangci_lint(), -- A async version of golangci-lint null-ls lint

        -- formatting
        null_ls.builtins.formatting.goimports,
        null_ls.builtins.formatting.golines.with({
          extra_args = {
            '--max-len=80',
            '--base-formatter=gofumpt',
          },
        }),
        null_ls.builtins.formatting.stylua.with({
          extra_args = {
            '--quote-style=AutoPreferSingle',
            '--indent-type=Spaces',
            '--indent-width=2',
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
  {
    'ray-x/go.nvim',
    dependencies = { -- optional packages
      'ray-x/guihua.lua',
      'neovim/nvim-lspconfig',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('go').setup()
    end,
    event = { 'CmdlineEnter' },
    ft = { 'go', 'gomod' },
    build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
  },
})
