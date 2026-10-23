-- ------------------------------------------------------------------------------------------------------------------------------
-- Markdown preview & render
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  -- Repo: selimacerbas/mdkite.nvim
  -- Browser live preview: mermaid (interactive SVG), local images, KaTeX, scroll sync
  'selimacerbas/mdkite.nvim',
  dependencies = { 'selimacerbas/kitehost.nvim' },
  lazy = true,
  cmd = { 'MdKite' },
  keys = {
    { '<leader>sp', '<cmd>MdKite toggle<cr>', desc = 'Preview Markdown' },
  },
  config = function()
    require('mdkite').setup({
      instance_mode = 'takeover', -- single browser tab reused across buffers
      default_theme = 'dark',
    })
  end,
})

table.insert(plugins, {
  -- Repo: MeanderingProgrammer/render-markdown.nvim
  -- In-buffer rendering: headings/tables/code blocks/checkboxes; raw text in insert mode
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  lazy = true,
  ft = { 'markdown' },
  opts = {},
})
