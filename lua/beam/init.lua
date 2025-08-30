local M = {}

local config = require('beam.config')
local operators = require('beam.operators')
local mappings = require('beam.mappings')
local text_objects = require('beam.text_objects')

-- Track registered text objects to avoid duplicates
M.registered_text_objects = {}

function M.setup(opts)
  config.setup(opts)

  if opts and opts.enable_default_text_objects ~= false then
    text_objects.setup_defaults()
  end

  if opts and opts.custom_text_objects then
    for key, obj in pairs(opts.custom_text_objects) do
      if type(obj) == 'table' and obj.select then
        text_objects.register_custom_text_object(key, obj)
      end
    end
  end

  mappings.setup()

  -- Auto-discover text objects if enabled
  if config.current.auto_discover_text_objects then
    -- Delay discovery slightly to allow plugins to load
    vim.defer_fn(function()
      local discovery = require('beam.text_object_discovery')
      local result = discovery.auto_register_text_objects({
        conflict_resolution = config.current.discovery_conflict_resolution or 'skip',
      })
      if config.current.show_discovery_notification and result then
        local msg = string.format(
          '[beam.nvim] Registered %d new text objects, %d motions (%d total available)',
          result.registered or 0,
          result.motions_registered or 0,
          (result.total or 0) + (result.motions_total or 0)
        )
        vim.notify(msg, vim.log.levels.INFO)
      end
    end, 500) -- Wait for lazy-loaded plugins
  end

  -- Expose core functions globally for health check and operator functionality
  _G.BeamSearchOperator = operators.BeamSearchOperator
  _G.BeamExecuteSearchOperator = operators.BeamExecuteSearchOperator

  -- Mark plugin as loaded
  vim.g.loaded_beam = true

  local has_which_key, which_key = pcall(require, 'which-key')
  if has_which_key then
    local prefix = config.current.prefix or ','
    which_key.register({
      [prefix] = {
        name = 'Remote Operators',
        y = { name = 'Yank' },
        d = { name = 'Delete' },
        c = { name = 'Change' },
        v = { name = 'Visual' },
      },
    })
  end
end

function M.is_text_object_registered(key)
  -- Check both runtime registrations and config
  return M.registered_text_objects[key] ~= nil or config.text_objects[key] ~= nil
end

function M.register_text_object(key, description)
  -- Avoid duplicate registrations
  if M.is_text_object_registered(key) then
    return false
  end

  if type(description) == 'table' and description.select then
    text_objects.register_custom_text_object(key, description)
  end

  config.register_text_object(key, type(description) == 'table' and description.desc or description)
  mappings.create_custom_mappings({
    [key] = type(description) == 'table' and description.desc or description,
  })

  M.registered_text_objects[key] = true
  return true
end

function M.register_text_objects(objects)
  for key, obj in pairs(objects) do
    M.register_text_object(key, obj)
  end
end

function M.get_config()
  return config.current
end

return M
