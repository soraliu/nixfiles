-- ------------------------------------------------------------------------------------------------------------------------------
-- Performance Optimization for Large Files
-- ------------------------------------------------------------------------------------------------------------------------------

-- Configuration
local config = {
  -- File size threshold in MB (default: 1MB)
  max_filesize = 1,
  -- Line count threshold (default: 10000 lines)
  max_lines = 10000,
}

-- Disable heavy features for large files
local function disable_heavy_features()
  vim.cmd('syntax clear')
  vim.opt_local.spell = false
  vim.opt_local.swapfile = false
  vim.opt_local.foldmethod = 'manual'
  vim.opt_local.undolevels = -1
  vim.opt_local.undoreload = 0
  vim.opt_local.list = false
  vim.opt_local.relativenumber = false
  vim.opt_local.cursorline = false
  vim.opt_local.cursorcolumn = false

  -- Disable LSP for this buffer
  vim.b.large_file = true
  vim.api.nvim_create_autocmd('LspAttach', {
    buffer = 0,
    callback = function(args)
      vim.schedule(function()
        vim.lsp.buf_detach_client(0, args.data.client_id)
      end)
    end,
  })

  -- Show notification
  vim.notify(
    'Large file detected! Some features have been disabled for better performance.',
    vim.log.levels.WARN,
    { title = 'Performance Mode' }
  )
end

-- Check if file is large
local function check_large_file()
  local buf = vim.api.nvim_get_current_buf()
  local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))

  if not ok or not stats then
    return false
  end

  -- Check file size
  local size_mb = stats.size / (1024 * 1024)
  if size_mb > config.max_filesize then
    return true
  end

  -- Check line count
  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_count > config.max_lines then
    return true
  end

  return false
end

-- Setup autocmd for large file detection
local function setup()
  vim.api.nvim_create_autocmd({ 'BufReadPre', 'FileReadPre' }, {
    group = vim.api.nvim_create_augroup('LargeFileOptimization', { clear = true }),
    callback = function()
      if check_large_file() then
        disable_heavy_features()
      end
    end,
  })
end

-- Initialize
setup()
