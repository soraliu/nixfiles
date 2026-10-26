-- ------------------------------------------------------------------------------------------------------------------------------
-- Markdown preview & render
-- ------------------------------------------------------------------------------------------------------------------------------
table.insert(plugins, {
  -- Repo: selimacerbas/mdkite.nvim
  -- Browser live preview: mermaid (interactive SVG), local images, KaTeX, scroll sync
  'selimacerbas/mdkite.nvim',
  -- lazy=true 不会传递给 dependencies, kitehost 不显式声明 lazy 会在每个 nvim 启动时加载
  -- (并在退出时打 "kitehost: stopped all instances." 通知); 跟随 mdkite 按需加载即可
  dependencies = { { 'selimacerbas/kitehost.nvim', lazy = true } },
  lazy = true,
  cmd = { 'MdKite' },
  keys = {
    { '<leader>sp', '<cmd>MdKite toggle<cr>', desc = 'Preview Markdown' },
  },
  config = function()
    require('mdkite').setup({
      instance_mode = 'takeover', -- single browser tab reused across buffers
      default_theme = 'dark',
      hooks = {
        -- takeover 模式下, 若别的 nvim 会话已持有 server 而其浏览器 tab 早已关闭,
        -- 本会话按 <leader>sp 会静默 join: 不开浏览器、无任何提示, 按键像失灵。
        -- 这里在 join 时补开一个 tab; primary/retarget 路径自身会开浏览器,
        -- 用 _is_primary 跳过避免双开 (该字段为 mdkite 私有状态, 依赖 lazy-lock 固定的 commit)。
        on_start = function(url)
          if require('mdkite')._is_primary then
            return
          end
          require('mdkite.util').open_in_browser(url)
        end,
      },
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
