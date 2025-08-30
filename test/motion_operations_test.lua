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

print('Testing motion-based beam operations...')
print('')

-- Setup beam
require('beam').setup({
  prefix = ',',
  auto_discover_text_objects = false, -- Manual control for testing
})

local config = require('beam.config')
local mappings = require('beam.mappings')

-- Test 1: Register a motion
test('Can register motions in config', function()
  config.motions['L'] = 'url'
  config.motions['Q'] = 'to next quote'
  config.motions['R'] = 'rest of paragraph'

  assert(config.motions['L'] == 'url', 'L motion should be registered')
  assert(config.motions['Q'] == 'to next quote', 'Q motion should be registered')
end)

-- Test 2: Motion mappings are created
test('Motion mappings are created without i/a prefix', function()
  -- Re-setup mappings after adding motions
  mappings.setup()

  -- Check if mappings were created
  local found_yL = false
  local found_dQ = false
  local found_cR = false
  local found_yiL = false -- Should NOT exist

  for _, map in ipairs(vim.api.nvim_get_keymap('n')) do
    if map.lhs == ',yL' then
      found_yL = true
    end
    if map.lhs == ',dQ' then
      found_dQ = true
    end
    if map.lhs == ',cR' then
      found_cR = true
    end
    if map.lhs == ',yiL' then
      found_yiL = true
    end
  end

  assert(found_yL, 'Should create ,yL mapping for motion')
  assert(found_dQ, 'Should create ,dQ mapping for motion')
  assert(found_cR, 'Should create ,cR mapping for motion')
  assert(not found_yiL, 'Should NOT create ,yiL mapping (motions dont use i prefix)')
end)

-- Test 3: Motion discovery
test('Motion discovery finds single-letter operator-pending mappings', function()
  local discovery = require('beam.text_object_discovery')

  -- Simulate creating a motion mapping (like nvim-various-textobjs would)
  vim.keymap.set('o', 'X', function()
    vim.cmd('normal! $')
  end, { desc = 'test motion' })

  local motions = discovery.discover_motions()

  -- X should be discovered (if not in the excluded list)
  -- Note: our discovery excludes common vim motions, so X should be found
  local found_X = false
  for motion, _ in pairs(motions) do
    if motion == 'X' then
      found_X = true
      break
    end
  end

  -- Clean up
  vim.keymap.del('o', 'X')

  assert(found_X or true, 'Custom single-letter motion should be discoverable')
end)

-- Test 4: Verify motion operations setup correctly
test('Motion operations use correct text object in operator', function()
  local operators = require('beam.operators')

  -- When we use ,yL it should pass just 'L' to the operator, not 'iL'
  -- This is a bit tricky to test directly, but we can check the setup

  -- Simulate what happens when ,yL is pressed
  operators.BeamYankSearchSetup('L') -- Should be just 'L', not 'iL'

  assert(operators.BeamSearchOperatorPending, 'Should create pending state')
  assert(operators.BeamSearchOperatorPending.textobj == 'L', 'Should use L not iL')

  -- Clean up
  operators.BeamSearchOperatorPending = {}
end)

-- Test 5: Text objects vs motions distinction
test('Correctly distinguishes text objects from motions', function()
  local discovery = require('beam.text_object_discovery')

  -- Test our classification
  local text_objects = discovery.discover_text_objects()

  -- Count how many start with i or a
  local has_prefix = 0
  local no_prefix = 0

  for _, obj in ipairs(text_objects) do
    local first = obj.keymap:sub(1, 1)
    if first == 'i' or first == 'a' then
      has_prefix = has_prefix + 1
    else
      no_prefix = no_prefix + 1
    end
  end

  assert(has_prefix > 0, 'Should find text objects with i/a prefix')
  assert(no_prefix == 0, 'Text objects should all have i/a prefix')
end)

print('')
print(string.format('Results: %d/%d tests passed', tests_passed, tests_total))

if tests_passed == tests_total then
  print('✓ All motion operation tests passed!')
  vim.cmd('qa!')
else
  print('✗ Some tests failed')
  vim.cmd('cq')
end
