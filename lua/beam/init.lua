local M = {}

local config = require('beam.config')
local operators = require('beam.operators')
local mappings = require('beam.mappings')

function M.setup(opts)
  config.setup(opts)
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
  config.register_text_object(key, description)
  mappings.create_custom_mappings({ [key] = description })
end

function M.register_text_objects(objects)
  config.register_text_objects(objects)
  mappings.create_custom_mappings(objects)
end

function M.get_config()
  return config.current
end

return M