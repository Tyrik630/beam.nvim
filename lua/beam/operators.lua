local M = {}
local config = require('beam.config')

_G.BeamSearchOperator = function(type)
  local pattern = vim.g.beam_search_operator_pattern
  local saved_pos = vim.g.beam_search_operator_saved_pos
  local textobj = vim.g.beam_search_operator_textobj
  local action = vim.g.beam_search_operator_action

  if not pattern or not textobj or not action then
    return
  end

  local saved_reg = vim.fn.getreg('"')
  local saved_reg_type = vim.fn.getregtype('"')
  local saved_search = vim.fn.getreg('/')

  local ok = pcall(function()
    local cfg = config.current
    local feedback_duration = cfg.visual_feedback_duration or 150

    if action == 'yank' then
      vim.cmd('normal v' .. textobj)
      vim.cmd('redraw')
      vim.cmd('sleep ' .. feedback_duration .. 'm')
      vim.cmd('normal! y')
    elseif action == 'delete' then
      vim.cmd('normal v' .. textobj)
      vim.cmd('redraw')
      vim.cmd('sleep ' .. feedback_duration .. 'm')
      vim.cmd('normal! d')
    elseif action == 'change' then
      -- For custom text objects, we need to select them first then change
      vim.cmd('normal v' .. textobj)
      vim.cmd('normal! c')
      vim.cmd('startinsert')
    elseif action == 'visual' then
      vim.cmd('normal v' .. textobj)
    elseif action == 'yankline' then
      vim.cmd('normal! yy')
    elseif action == 'deleteline' then
      vim.cmd('normal! dd')
    elseif action == 'changeline' then
      vim.cmd('normal! cc')
      vim.cmd('startinsert')
    elseif action == 'visualline' then
      vim.cmd('normal! V')
    end
  end)

  if ok then
    if (action == 'yank' or action == 'delete' or action == 'yankline' or action == 'deleteline') and saved_pos then
      vim.fn.setpos('.', saved_pos)
    end

    local cfg = config.current
    if cfg.clear_highlight and action ~= 'change' and action ~= 'visual' and action ~= 'changeline' and action ~= 'visualline' then
      vim.defer_fn(function()
        vim.cmd('nohlsearch')
        vim.fn.setreg('/', saved_search)
      end, cfg.clear_highlight_delay or 500)
    end
  else
    if saved_pos then
      vim.fn.setpos('.', saved_pos)
    end
    vim.fn.setreg('"', saved_reg, saved_reg_type)
    vim.fn.setreg('/', saved_search)
    vim.cmd('nohlsearch')
  end

  vim.g.beam_search_operator_pattern = nil
  vim.g.beam_search_operator_saved_pos = nil
  vim.g.beam_search_operator_textobj = nil
  vim.g.beam_search_operator_action = nil
end

_G.BeamSearchOperatorPending = {}

_G.BeamExecuteSearchOperator = function()
  local pending = _G.BeamSearchOperatorPending
  if not pending or not pending.action or not pending.textobj then
    vim.cmd('silent! autocmd! BeamSearchOperatorExecute')
    return
  end

  local pattern = vim.fn.getreg('/')
  if not pattern or pattern == '' then
    _G.BeamSearchOperatorPending = {}
    vim.cmd('silent! autocmd! BeamSearchOperatorExecute')
    vim.g.beam_search_operator_indicator = nil
    vim.cmd('redrawstatus')
    return
  end

  vim.g.beam_search_operator_pattern = pattern
  vim.g.beam_search_operator_saved_pos = pending.saved_pos_for_yank
  vim.g.beam_search_operator_textobj = pending.textobj
  vim.g.beam_search_operator_action = pending.action

  _G.BeamSearchOperatorPending = {}

  vim.opt.operatorfunc = 'v:lua.BeamSearchOperator'
  vim.api.nvim_feedkeys('g@l', 'n', false)
end

function M.create_setup_function(action, save_pos)
  return function(textobj)
    _G.BeamSearchOperatorPending = {
      action = action,
      textobj = textobj,
      saved_pos_for_yank = save_pos and vim.fn.getpos('.') or nil,
    }

    vim.g.beam_search_operator_indicator = action .. '[' .. textobj .. ']'

    vim.cmd([[
      silent! augroup! BeamSearchOperatorExecute
      augroup BeamSearchOperatorExecute
        autocmd!
        autocmd CmdlineLeave / ++once lua BeamExecuteSearchOperator(); vim.g.beam_search_operator_indicator = nil; vim.cmd('redrawstatus')
      augroup END
    ]])

    vim.cmd('redrawstatus')
    return '/'
  end
end

_G.BeamYankSearchSetup = M.create_setup_function('yank', true)
_G.BeamDeleteSearchSetup = M.create_setup_function('delete', true)
_G.BeamChangeSearchSetup = M.create_setup_function('change', false)
_G.BeamVisualSearchSetup = M.create_setup_function('visual', false)

return M