#!/usr/bin/env -S nvim -l

-- Simple smoke test for CI
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

print('Running beam.nvim smoke tests...')
print('')

-- Test that plugin loads
test('Plugin loads successfully', function()
  local ok, beam = pcall(require, 'beam')
  assert(ok, 'Failed to load beam module')
end)

-- Test setup
test('Setup configures plugin correctly', function()
  local beam = require('beam')
  beam.setup({ prefix = ',' })
  local config = beam.get_config()
  assert(config.prefix == ',', 'Config prefix not set correctly')
  assert(config.visual_feedback_duration == 150, 'Default visual feedback duration incorrect')
end)

-- Test that global functions are created
test('Global operator functions created', function()
  assert(_G.BeamSearchOperator, 'BeamSearchOperator not created')
  assert(_G.BeamYankSearchSetup, 'BeamYankSearchSetup not created')
  assert(_G.BeamDeleteSearchSetup, 'BeamDeleteSearchSetup not created')
  assert(_G.BeamChangeSearchSetup, 'BeamChangeSearchSetup not created')
  assert(_G.BeamVisualSearchSetup, 'BeamVisualSearchSetup not created')
end)

-- Test that mappings are created
test('Keymaps registered for common text objects', function()
  local keymaps = vim.api.nvim_get_keymap('n')
  local required_mappings = { ',yi"', ',ya"', ',yip', ',yiw', ',Y', ',D' }
  local found = {}

  for _, map in ipairs(keymaps) do
    for _, req in ipairs(required_mappings) do
      if map.lhs == req then
        found[req] = true
      end
    end
  end

  for _, req in ipairs(required_mappings) do
    assert(found[req], string.format('Mapping %s not created', req))
  end
end)

-- Test custom text object registration
test('Custom text objects can be registered', function()
  local beam = require('beam')
  beam.register_text_object('z', 'test object')
  local config_module = require('beam.config')
  assert(config_module.text_objects['z'] == 'test object', 'Custom text object not registered')
end)

-- Test pending operation state
test('Pending operation state is set correctly', function()
  _G.BeamYankSearchSetup('i"')
  assert(_G.BeamSearchOperatorPending, 'Pending state not created')
  assert(_G.BeamSearchOperatorPending.action == 'yank', 'Action not set correctly')
  assert(_G.BeamSearchOperatorPending.textobj == 'i"', 'Text object not set correctly')
end)

print('')
print(string.format('Results: %d/%d tests passed', tests_passed, tests_total))

if tests_passed == tests_total then
  print('✓ All tests passed!')
  vim.cmd('qa!')
else
  print('✗ Some tests failed')
  vim.cmd('cq')
end
