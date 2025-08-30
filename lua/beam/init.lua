local M = {}

local config = require('beam.config')
local operators = require('beam.operators')
local mappings = require('beam.mappings')
local text_objects = require('beam.text_objects')

function M.setup(opts)
  config.setup(opts)
  
  -- Setup custom text objects with actual implementations
  if opts and opts.enable_default_text_objects ~= false then
    text_objects.setup_defaults()
  end
  
  -- Setup custom text objects from config
  if opts and opts.custom_text_objects then
    for key, obj in pairs(opts.custom_text_objects) do
      if type(obj) == 'table' and obj.select then
        text_objects.register_custom_text_object(key, obj)
      end
    end
  end
  
  mappings.setup()
  
  local has_which_key, which_key = pcall(require, 'which-key')
  if has_which_key then
    local prefix = config.current.prefix or ','
    which_key.register({
      [prefix] = {
        name = "Remote Operators",
        y = { name = "Yank" },
        d = { name = "Delete" },
        c = { name = "Change" },
        v = { name = "Visual" },
      }
    })
  end
end

function M.register_text_object(key, description)
  -- If it's a table with a select function, register as custom text object
  if type(description) == 'table' and description.select then
    text_objects.register_custom_text_object(key, description)
  end
  
  config.register_text_object(key, type(description) == 'table' and description.desc or description)
  mappings.create_custom_mappings({ [key] = type(description) == 'table' and description.desc or description })
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