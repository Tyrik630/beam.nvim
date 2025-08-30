if vim.g.loaded_beam then
  return
end
vim.g.loaded_beam = 1

vim.api.nvim_create_user_command('BeamReload', function()
  package.loaded['beam'] = nil
  package.loaded['beam.config'] = nil
  package.loaded['beam.operators'] = nil
  package.loaded['beam.mappings'] = nil
  require('beam').setup(vim.g.beam_config or {})
  vim.notify('Beam.nvim reloaded', vim.log.levels.INFO)
end, { desc = 'Reload beam.nvim plugin' })

vim.api.nvim_create_user_command('BeamShowTextObjects', function()
  local discovery = require('beam.text_object_discovery')
  local categorized, all = discovery.get_available_text_objects()

  print('=== Available Text Objects ===')
  for category, objects in pairs(categorized) do
    if #objects > 0 then
      print(string.format('\n%s (%d):', category:upper(), #objects))
      for _, obj in ipairs(objects) do
        print(string.format('  %s - %s', obj.keymap, obj.desc))
      end
    end
  end
  print(string.format('\nTotal: %d text objects discovered', #all))
end, { desc = 'Show discovered text objects' })

vim.api.nvim_create_user_command('BeamDiscoverNow', function()
  local discovery = require('beam.text_object_discovery')
  local result = discovery.auto_register_text_objects({
    conflict_resolution = 'skip',
  })
  vim.notify(
    string.format(
      '[beam.nvim] Manually discovered: %d new, %d skipped, %d total',
      result.registered or 0,
      result.skipped or 0,
      result.total or 0
    ),
    vim.log.levels.INFO
  )
end, { desc = 'Manually trigger text object discovery' })
