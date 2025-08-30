local M = {}

M.check = function()
  local health = vim.health or require('health')
  local start = health.start or health.report_start
  local ok = health.ok or health.report_ok
  local warn = health.warn or health.report_warn
  local error = health.error or health.report_error
  
  start('beam.nvim')
  
  -- Check if plugin is loaded
  if vim.g.loaded_beam then
    ok('Plugin loaded')
  else
    error('Plugin not loaded. Try running :BeamReload')
  end
  
  -- Check configuration
  local config_ok, config = pcall(require, 'beam.config')
  if config_ok and config.current then
    ok('Configuration loaded')
    
    -- Check prefix conflicts
    local prefix = config.current.prefix or ','
    local keymaps = vim.api.nvim_get_keymap('n')
    local conflicts = {}
    
    for _, map in ipairs(keymaps) do
      if map.lhs:sub(1, #prefix) == prefix and not map.lhs:match('beam') and not map.desc:match('[Ss]earch') then
        table.insert(conflicts, map.lhs)
      end
    end
    
    if #conflicts > 0 and #conflicts < 5 then
      warn('Potential prefix conflicts found: ' .. table.concat(conflicts, ', '))
      warn('Consider using a different prefix in setup()')
    else
      ok('No significant prefix conflicts detected')
    end
  else
    error('Configuration not loaded')
  end
  
  -- Check if keymaps are created
  local cfg = config and config.current or {}
  local test_map = (cfg.prefix or ',') .. 'yi"'
  local found = false
  for _, map in ipairs(vim.api.nvim_get_keymap('n')) do
    if map.lhs == test_map then
      found = true
      break
    end
  end
  
  if found then
    ok('Keymaps created successfully')
  else
    error('Keymaps not found. Check your configuration')
  end
  
  -- Check statusline integration
  if vim.g.beam_search_operator_indicator ~= nil then
    ok('Statusline indicator active: ' .. vim.g.beam_search_operator_indicator)
  else
    ok('Statusline indicator available (currently inactive)')
  end
  
  -- Check global functions
  if _G.BeamSearchOperator and _G.BeamExecuteSearchOperator then
    ok('Core operator functions loaded')
  else
    error('Core operator functions not loaded')
  end
end

return M