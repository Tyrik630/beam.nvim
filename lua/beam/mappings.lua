local M = {}
local config = require('beam.config')

function M.setup()
  local cfg = config.current
  local prefix = cfg.prefix or ','
  
  for op_key, op_info in pairs(config.operators) do
    for obj_key, obj_name in pairs(config.text_objects) do
      local key_i = prefix .. op_key .. 'i' .. obj_key
      local desc_i = 'Search & ' .. op_info.verb .. ' inside ' .. obj_name
      vim.keymap.set('n', key_i, function()
        local result = _G['Beam' .. op_info.func]('i' .. obj_key)
        if result == '/' then
          vim.api.nvim_feedkeys('/', 'n', false)
        end
      end, { desc = desc_i })
      
      if not (obj_key:match('[bB]')) then
        local key_a = prefix .. op_key .. 'a' .. obj_key
        local desc_a = 'Search & ' .. op_info.verb .. ' around ' .. obj_name
        vim.keymap.set('n', key_a, function()
          local result = _G['Beam' .. op_info.func]('a' .. obj_key)
          if result == '/' then
            vim.api.nvim_feedkeys('/', 'n', false)
          end
        end, { desc = desc_a })
      end
    end
  end
  
  for op_key, op_info in pairs(config.line_operators) do
    local key = prefix .. op_key
    local desc = 'Search & ' .. op_info.verb
    vim.keymap.set('n', key, function()
      _G.BeamSearchOperatorPending = {
        action = op_info.action,
        textobj = '',
        saved_pos_for_yank = op_info.save_pos and vim.fn.getpos('.') or nil,
      }
      
      vim.g.beam_search_operator_indicator = op_info.verb
      
      vim.cmd([[
        silent! augroup! BeamSearchOperatorExecute
        augroup BeamSearchOperatorExecute
          autocmd!
          autocmd CmdlineLeave / ++once lua BeamExecuteSearchOperator(); vim.g.beam_search_operator_indicator = nil; vim.cmd('redrawstatus')
        augroup END
      ]])
      
      vim.cmd('redrawstatus')
      vim.api.nvim_feedkeys('/', 'n', false)
    end, { desc = desc })
  end
end

function M.create_custom_mappings(text_objects)
  local cfg = config.current
  local prefix = cfg.prefix or ','
  
  for obj_key, obj_name in pairs(text_objects) do
    for op_key, op_info in pairs(config.operators) do
      local key_i = prefix .. op_key .. 'i' .. obj_key
      local desc_i = 'Search & ' .. op_info.verb .. ' inside ' .. obj_name
      vim.keymap.set('n', key_i, function()
        local result = _G['Beam' .. op_info.func]('i' .. obj_key)
        if result == '/' then
          vim.api.nvim_feedkeys('/', 'n', false)
        end
      end, { desc = desc_i })
      
      if not (obj_key:match('[bB]')) then
        local key_a = prefix .. op_key .. 'a' .. obj_key
        local desc_a = 'Search & ' .. op_info.verb .. ' around ' .. obj_name
        vim.keymap.set('n', key_a, function()
          local result = _G['Beam' .. op_info.func]('a' .. obj_key)
          if result == '/' then
            vim.api.nvim_feedkeys('/', 'n', false)
          end
        end, { desc = desc_a })
      end
    end
  end
end

return M