-- ------------------------------------------------------------------------------------------------------------------------------
-- theme
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  {
    'EdenEast/nightfox.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('nightfox').setup({
        options = {
          styles = {
            -- comments = "italic",
            -- keywords = "bold",
            -- types = "italic,bold",
          },
        },
        palettes = {
          -- Custom duskfox with black background
          terafox = {
            -- black   = Shade.new("#2F3239", "#4e5157", "#282a30"),
            red = '#fc5d7c',
            green = '#9ed072',
            yellow = '#e7c664',
            blue = '#76cce0',
            magenta = '#fc5d7c',
            cyan = '#a7df78',
            -- white   = Shade.new("#ebebeb", "#eeeeee", "#c8c8c8"),
            orange = '#f39660',
            -- pink    = Shade.new("#cb7985", "#d38d97", "#ad6771"),

            comment = '#7f8490',

            -- bg0     = "#0f1c1e", -- Dark bg (status line and float)
            bg1 = '#000000', -- Black background
            -- bg2     = "#1d3337", -- Lighter bg (colorcolm folds)
            -- bg3     = "#254147", -- Lighter bg (cursor line)
            -- bg4     = "#2d4f56", -- Conceal, border fg

            -- fg0     = "#eaeeee", -- Lighter fg
            -- fg1     = "#e6eaea", -- Default fg
            -- fg2     = "#cbd9d8", -- Darker fg (status line)
            -- fg3     = "#587b7b", -- Darker fg (line numbers, fold colums)

            -- sel0    = "#293e40", -- Popup bg, visual selection bg
            -- sel1    = "#425e5e", -- Popup sel bg, search bg
          },
        },
        specs = {
          terafox = {
            syntax = {
              -- bracket     = spec.fg2,           -- Brackets and Punctuation
              -- builtin0    = pal.red.base,       -- Builtin variable
              -- builtin1    = pal.cyan.bright,    -- Builtin type
              -- builtin2    = pal.orange.bright,  -- Builtin const
              -- builtin3    = pal.red.bright,     -- Not used
              -- comment     = pal.comment,        -- Comment
              -- conditional = pal.magenta.bright, -- Conditional and loop
              -- const       = pal.orange.bright,  -- Constants, imports and booleans
              -- dep         = spec.fg3,           -- Deprecated
              -- field       = pal.blue.base,      -- Field
              -- func        = pal.blue.bright,    -- Functions and Titles
              -- ident       = pal.cyan.base,      -- Identifiers
              -- keyword     = pal.magenta.base,   -- Keywords
              -- number      = pal.orange.base,    -- Numbers
              -- operator    = spec.fg2,           -- Operators
              -- preproc     = pal.pink.bright,    -- PreProc
              -- regex       = pal.yellow.bright,  -- Regex
              -- statement   = pal.magenta.base,   -- Statements
              -- string      = pal.green.base,     -- Strings
              -- type        = pal.yellow.base,    -- Types
              -- variable    = pal.white.base,     -- Variables
            },
          },
        },
      })

      vim.cmd([[
        colorscheme terafox
      ]])
    end,
  },
  {
    'NvChad/nvim-colorizer.lua', -- show colors
    config = function()
      require('colorizer').setup()
    end,
  },
  {
    'soraliu/colortils.nvim',
    config = function()
      require('colortils').setup({
        mappings = keysPluginColortils(),
      })
    end,
  },
  {
    'levouh/tint.nvim', -- Dim inactive windows
    config = function()
      require('tint').setup({
        tint = -60, -- Darken colors, use a positive value to brighten
        saturation = 0.318, -- Saturation to preserve
      })
    end,
  },

  {
    'mvllow/modes.nvim',
    branch = 'main',
    config = function()
      require('modes').setup({
        colors = {
          copy = '#f5c359',
          delete = '#c75c6a',
          insert = '#3A4C2A',
          visual = '#8A3344',
        },

        -- Set opacity for cursorline and number background
        line_opacity = 0.618,

        -- Enable cursor highlights
        set_cursor = true,

        -- Enable cursorline initially, and disable cursorline for inactive windows
        -- or ignored filetypes
        set_cursorline = true,

        -- Enable line number highlights to match cursorline
        set_number = false,

        -- Disable modes highlights in specified filetypes
        -- Please PR commonly ignored filetypes
        ignore_filetypes = { 'NvimTree', 'TelescopePrompt' },
      })
    end,
  },
  -- Disable reactive.nvim because it's not working properly with telescope, need to upgrade nvim
  -- TL;DR: https://github.com/rasulomaroff/reactive.nvim/issues/5
  -- {
  --   'rasulomaroff/reactive.nvim', -- Change colors based on mode
  --   config = function()
  --     require('reactive').add_preset({
  --       name = 'cursorline',
  --       init = function()
  --         vim.opt.cursorline = true
  --       end,
  --       modes = {
  --         n = {
  --           winhl = {
  --             CursorLine = { bg = '#254046' },
  --             CursorLineNr = { fg = '#4F656A' },
  --           },
  --         },
  --         i = {
  --           winhl = {
  --             CursorLine = { bg = '#3A4C2A' },
  --             CursorLineNr = { fg = '#9ed072' },
  --           },
  --         },
  --         c = {
  --           winhl = {
  --             CursorLine = { bg = '#3A4C2A' },
  --             CursorLineNr = { fg = '#9ed072' },
  --           },
  --         },
  --         -- visual
  --         [{ 'v', 'V', '\x16' }] = {
  --           winhl = {
  --             CursorLine = { bg = '#8A3344' },
  --             CursorLineNr = { fg = '#fc5d7c' },
  --             Visual = { bg = '#8A3344' },
  --           },
  --         },
  --         -- select
  --         [{ 's', 'S', '\x13' }] = {
  --           winhl = {
  --             CursorLine = { bg = '#BE764B' },
  --             CursorLineNr = { fg = '#f39660' },
  --             Visual = { bg = '#BE764B' },
  --           },
  --         },
  --         -- replace
  --         R = {
  --           winhl = {
  --             CursorLine = { bg = '#BE764B' },
  --             CursorLineNr = { fg = '#f39660' },
  --             Visual = { bg = '#BE764B' },
  --           },
  --         },
  --       },
  --     })
  --   end,
  -- },
})
