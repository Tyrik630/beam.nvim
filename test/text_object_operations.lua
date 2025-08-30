#!/usr/bin/env -S nvim -l

-- Test actual text object operations
vim.opt.rtp:prepend(vim.fn.getcwd())

local tests_passed = 0
local tests_total = 0

local function test(name, fn)
  tests_total = tests_total + 1
  local ok, err = pcall(fn)
  if ok then
    tests_passed = tests_passed + 1
    print(string.format("  ✓ %s", name))
  else
    print(string.format("  ✗ %s: %s", name, err))
  end
end

-- Setup beam with markdown code block support
require("beam").setup({ 
  prefix = ',', 
  visual_feedback_duration = 10,
  enable_default_text_objects = true  -- This will register 'im' and 'am' for markdown code blocks
})

print("Testing beam.nvim text object operations...")
print("")

-- Suppress visual mode and other messages during tests
vim.o.showcmd = false
vim.o.showmode = false
vim.o.report = 999  -- Don't report line changes

-- Helper function to set buffer content
local function set_buffer(lines)
  vim.cmd('enew!')
  if type(lines) == 'string' then
    lines = {lines}
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, {1, 0})
end

-- Helper to simulate beam operation
local function perform_beam_operation(action, textobj, target_pos)
  local initial_pos = vim.fn.getpos('.')
  
  -- Setup the operation (simulates pressing ,y/d/c/v + textobj)
  if action == 'yank' then
    _G.BeamYankSearchSetup(textobj)
  elseif action == 'delete' then
    _G.BeamDeleteSearchSetup(textobj)
  elseif action == 'change' then
    _G.BeamChangeSearchSetup(textobj)
  elseif action == 'visual' then
    _G.BeamVisualSearchSetup(textobj)
  end
  
  -- Move to target position (simulates search finding the target)
  if target_pos then
    vim.api.nvim_win_set_cursor(0, target_pos)
  end
  
  -- Copy pending state to global vars (simulates what happens after search)
  if _G.BeamSearchOperatorPending then
    vim.g.beam_search_operator_pattern = ''
    vim.g.beam_search_operator_textobj = _G.BeamSearchOperatorPending.textobj
    vim.g.beam_search_operator_action = _G.BeamSearchOperatorPending.action
    vim.g.beam_search_operator_saved_pos = _G.BeamSearchOperatorPending.saved_pos_for_yank
  end
  
  -- Execute the operation
  _G.BeamSearchOperator('char')
  
  return initial_pos
end

print("Yank operations:")
test("  yi\" - yank inside quotes, preserve cursor", function()
  set_buffer('foo "bar" baz')
  local initial_pos = perform_beam_operation('yank', 'i"', {1, 5})
  
  local yanked = vim.fn.getreg('"')
  assert(yanked == 'bar', string.format("Should yank 'bar', got '%s'", yanked))
  
  local final_pos = vim.fn.getpos('.')
  assert(final_pos[2] == initial_pos[2] and final_pos[3] == initial_pos[3], 
    "Cursor should return to original position")
end)

test("  ya\" - yank around quotes, preserve cursor", function()
  set_buffer('foo "bar" baz')
  local initial_pos = perform_beam_operation('yank', 'a"', {1, 5})
  
  local yanked = vim.fn.getreg('"')
  -- The 'a"' text object might include trailing space on some Neovim versions
  assert(yanked == '"bar"' or yanked == '"bar" ', 
    string.format("Should yank '\"bar\"', got '%s'", yanked))
  
  local final_pos = vim.fn.getpos('.')
  assert(final_pos[2] == initial_pos[2] and final_pos[3] == initial_pos[3], 
    "Cursor should return to original position")
end)

test("  yiw - yank inside word", function()
  set_buffer('foo bar baz')
  perform_beam_operation('yank', 'iw', {1, 4})
  
  local yanked = vim.fn.getreg('"')
  assert(yanked == 'bar', string.format("Should yank 'bar', got '%s'", yanked))
end)

test("  yi( - yank inside parentheses", function()
  set_buffer('foo(bar, baz)end')
  perform_beam_operation('yank', 'i(', {1, 4})
  
  local yanked = vim.fn.getreg('"')
  assert(yanked == 'bar, baz', string.format("Should yank 'bar, baz', got '%s'", yanked))
end)

print("")
print("Delete operations:")
test("  di\" - delete inside quotes, preserve cursor", function()
  set_buffer('foo "bar" baz')
  local initial_pos = perform_beam_operation('delete', 'i"', {1, 5})
  
  local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)[1]
  assert(result == 'foo "" baz', string.format("Should leave empty quotes, got '%s'", result))
  
  local final_pos = vim.fn.getpos('.')
  assert(final_pos[2] == initial_pos[2] and final_pos[3] == initial_pos[3], 
    "Cursor should return to original position")
end)

test("  daw - delete around word", function()
  set_buffer('foo bar baz')
  perform_beam_operation('delete', 'aw', {1, 4})
  
  local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)[1]
  assert(result == 'foo baz' or result == 'foobaz', 
    string.format("Should delete 'bar' with space, got '%s'", result))
end)

test("  di[ - delete inside brackets", function()
  set_buffer('foo[bar]baz')
  perform_beam_operation('delete', 'i[', {1, 4})
  
  local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)[1]
  assert(result == 'foo[]baz', string.format("Should leave empty brackets, got '%s'", result))
end)

print("")
print("Change operations:")
test("  ci\" - change inside quotes (setup)", function()
  set_buffer('foo "bar" baz')
  
  -- Test that change setup creates correct state
  _G.BeamChangeSearchSetup('i"')
  
  assert(_G.BeamSearchOperatorPending, "Should create pending state")
  assert(_G.BeamSearchOperatorPending.action == 'change', "Should set change action")
  assert(_G.BeamSearchOperatorPending.textobj == 'i"', "Should set text object")
  assert(not _G.BeamSearchOperatorPending.saved_pos_for_yank, 
    "Should not save position for change (cursor should move)")
end)

print("")
print("Other operations:")
test("  yip - yank inside paragraph", function()
  set_buffer({
    'first line',
    'second line',
    '',
    'third line'
  })
  perform_beam_operation('yank', 'ip', {1, 0})
  
  local yanked = vim.fn.getreg('"')
  assert(yanked:match('first line'), "Should include first line")
  assert(yanked:match('second line'), "Should include second line")
  assert(not yanked:match('third line'), "Should not include third line")
end)

print("")
print("Line operations:")
test("  Y - yank entire line", function()
  set_buffer({
    'first line',
    'second line',
    'third line'
  })
  
  -- Setup line yank (,Y)
  vim.api.nvim_win_set_cursor(0, {2, 0})
  _G.BeamYankSearchSetup('_')
  
  vim.g.beam_search_operator_pattern = ''
  vim.g.beam_search_operator_textobj = '_'
  vim.g.beam_search_operator_action = 'yankline'
  vim.g.beam_search_operator_saved_pos = vim.fn.getpos('.')
  
  _G.BeamSearchOperator('line')
  
  local yanked = vim.fn.getreg('"')
  assert(yanked:match('second line'), "Should yank entire second line")
end)

test("  D - delete entire line", function()
  set_buffer({
    'first line',
    'second line',
    'third line'
  })
  
  vim.api.nvim_win_set_cursor(0, {2, 0})
  _G.BeamDeleteSearchSetup('_')
  
  vim.g.beam_search_operator_pattern = ''
  vim.g.beam_search_operator_textobj = '_'
  vim.g.beam_search_operator_action = 'deleteline'
  vim.g.beam_search_operator_saved_pos = vim.fn.getpos('.')
  
  _G.BeamSearchOperator('line')
  
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert(#lines == 2, string.format("Should have 2 lines left, got %d", #lines))
  assert(not table.concat(lines, '\n'):match('second line'), "Second line should be deleted")
end)

print("")
print("Visual mode:")
test("  vi\" - visual select inside quotes", function()
  set_buffer('foo "bar" baz')
  local initial_pos = perform_beam_operation('visual', 'i"', {1, 5})
  
  local mode = vim.fn.mode()
  assert(mode == 'v' or mode == 'V', string.format("Should be in visual mode, got '%s'", mode))
  
  -- Exit visual mode with Escape
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
  
  local final_pos = vim.fn.getpos('.')
  assert(final_pos[2] ~= initial_pos[2] or final_pos[3] ~= initial_pos[3], 
    "Cursor should move to selection")
end)

print("")
print("Markdown code blocks:")
test("  yim - yank inside markdown code block", function()
  set_buffer({
    'text before',
    '```',
    'code inside',
    'more code',
    '```',
    'text after'
  })
  
  -- Position inside code block
  vim.api.nvim_win_set_cursor(0, {3, 0})
  
  -- Yank inside markdown code block
  _G.BeamYankSearchSetup('im')
  vim.g.beam_search_operator_pattern = ''
  vim.g.beam_search_operator_textobj = _G.BeamSearchOperatorPending.textobj
  vim.g.beam_search_operator_action = _G.BeamSearchOperatorPending.action
  vim.g.beam_search_operator_saved_pos = _G.BeamSearchOperatorPending.saved_pos_for_yank
  
  _G.BeamSearchOperator('line')
  
  local yanked = vim.fn.getreg('"')
  assert(yanked:match('code inside'), "Should yank code inside block")
  assert(yanked:match('more code'), "Should yank all code in block")
  assert(not yanked:match('```'), "Should not include backticks")
end)

test("  dam - delete around markdown code block", function()
  set_buffer({
    'text before',
    '```',
    'code inside',
    '```',
    'text after'
  })
  
  vim.api.nvim_win_set_cursor(0, {3, 0})
  
  -- Delete around markdown code block
  _G.BeamDeleteSearchSetup('am')
  vim.g.beam_search_operator_pattern = ''
  vim.g.beam_search_operator_textobj = _G.BeamSearchOperatorPending.textobj
  vim.g.beam_search_operator_action = _G.BeamSearchOperatorPending.action
  vim.g.beam_search_operator_saved_pos = _G.BeamSearchOperatorPending.saved_pos_for_yank
  
  _G.BeamSearchOperator('line')
  
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  -- Should have deleted everything including backticks
  assert(lines[1] == 'text before', "Should keep text before")
  assert(lines[2] == 'text after', "Should have text after immediately following")
end)

print("")
print("Setup functions:")
test("  YankSearchSetup creates correct pending state", function()
  _G.BeamYankSearchSetup('i"')
  assert(_G.BeamSearchOperatorPending, "Should create pending state")
  assert(_G.BeamSearchOperatorPending.action == 'yank', "Should set yank action")
  assert(_G.BeamSearchOperatorPending.textobj == 'i"', "Should set text object")
  assert(_G.BeamSearchOperatorPending.saved_pos_for_yank, "Should save position for yank")
end)

test("  ChangeSearchSetup creates correct pending state", function()
  _G.BeamChangeSearchSetup('iw')
  assert(_G.BeamSearchOperatorPending, "Should create pending state")
  assert(_G.BeamSearchOperatorPending.action == 'change', "Should set change action")
  assert(_G.BeamSearchOperatorPending.textobj == 'iw', "Should set text object")
  assert(not _G.BeamSearchOperatorPending.saved_pos_for_yank, "Should not save position for change")
end)

print("")
print(string.format("Results: %d/%d tests passed", tests_passed, tests_total))

if tests_passed == tests_total then
  print("✓ All text object operations work correctly!")
  vim.cmd('qa!')
else
  print("✗ Some operations failed")
  vim.cmd('cq')
end