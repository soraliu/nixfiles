local Shade = require('nightfox.lib.shade')
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
