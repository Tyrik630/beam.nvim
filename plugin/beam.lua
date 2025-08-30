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