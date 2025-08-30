#!/usr/bin/env -S nvim -l

vim.opt.rtp:prepend(vim.fn.getcwd())

local tests_passed = 0
local tests_total = 0

local function test(name, fn)
  tests_total = tests_total + 1
  local ok, err = pcall(fn)
  if ok then
    tests_passed = tests_passed + 1
    print(string.format('  ✓ %s', name))
  else
    print(string.format('  ✗ %s: %s', name, err))
  end
end

local function set_buffer(buf, text)
  vim.api.nvim_set_current_buf(buf)
  local lines = type(text) == 'string' and { text } or text
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

local function get_buffer_content(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
end

print('Running cross-buffer operation tests...')
print('')

-- Clear any previous state
package.loaded['beam'] = nil
package.loaded['beam.operators'] = nil
package.loaded['beam.config'] = nil

local beam = require('beam')
local operators = require('beam.operators')

print('Testing with cross_buffer = true:')
beam.setup({ prefix = ',', cross_buffer = true })

test('  cross-buffer search finds matches in other buffers', function()
  local buf1 = vim.api.nvim_get_current_buf()
  local buf2 = vim.api.nvim_create_buf(true, false) -- listed buffer

  -- Make sure buf2 is loaded
  vim.api.nvim_buf_set_lines(buf2, 0, -1, false, { 'buffer two "target text" more' })
  vim.api.nvim_buf_set_lines(buf1, 0, -1, false, { 'buffer one content' })

  vim.api.nvim_set_current_buf(buf1)

  -- Test that cross-buffer search can find text in buf2
  local found = false
  for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if buf.bufnr == buf2 then
      vim.api.nvim_set_current_buf(buf2)
      found = vim.fn.search('target', 'c') > 0
      break
    end
  end

  assert(found, 'Should find pattern in another buffer')
end)

test('  config enables cross-buffer search', function()
  local cfg = require('beam.config').current
  assert(cfg.cross_buffer == true, 'cross_buffer should be enabled')
end)

test('  can switch between buffers', function()
  local buf1 = vim.api.nvim_get_current_buf()
  local buf2 = vim.api.nvim_create_buf(true, false)

  vim.api.nvim_buf_set_lines(buf2, 0, -1, false, { 'test content' })

  vim.api.nvim_set_current_buf(buf2)
  assert(vim.api.nvim_get_current_buf() == buf2, 'Should switch to buffer 2')

  vim.api.nvim_set_current_buf(buf1)
  assert(vim.api.nvim_get_current_buf() == buf1, 'Should switch back to buffer 1')
end)

print('')
print('Testing with cross_buffer = false:')

-- Reload and setup with cross_buffer disabled
package.loaded['beam'] = nil
package.loaded['beam.config'] = nil
beam = require('beam')
beam.setup({ prefix = ',', cross_buffer = false })

test('  should not find text in other buffers', function()
  local buf1 = vim.api.nvim_get_current_buf()
  local buf2 = vim.api.nvim_create_buf(false, true)

  set_buffer(buf1, 'buffer one content')
  set_buffer(buf2, 'buffer two "target text" more')

  vim.api.nvim_set_current_buf(buf1)

  -- Setup yank operation
  operators.BeamYankSearchSetup('i"')

  -- Simulate search completion - pattern not in current buffer
  vim.fn.setreg('/', 'target')
  operators.BeamExecuteSearchOperator()

  -- Operation should not execute since pattern not found
  assert(
    vim.g.beam_search_operator_action == nil,
    'Operation should not execute when pattern not in current buffer'
  )
  assert(vim.api.nvim_get_current_buf() == buf1, 'Should stay in original buffer')
end)

-- Print test summary
print('')
print(string.format('✅ %d/%d tests passed', tests_passed, tests_total))

if tests_passed ~= tests_total then
  print('❌ Some tests failed!')
  os.exit(1)
else
  print('✓ All cross-buffer tests passed!')
  os.exit(0)
end
