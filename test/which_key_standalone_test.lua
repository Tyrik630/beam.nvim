#!/usr/bin/env nvim -l
-- Standalone test for which-key integration

-- Add beam.nvim to runtime path
vim.opt.rtp:prepend('.')

-- Mock which-key module
local which_key_calls = {}
package.loaded['which-key'] = {
  add = function(spec)
    table.insert(which_key_calls, spec)
    return true
  end,
}

-- Load and setup beam
local beam = require('beam')
beam.setup({
  prefix = ',',
})

-- Verify which-key.add was called with the new spec format
assert(#which_key_calls > 0, 'which-key.add should have been called')

local spec = which_key_calls[1]
assert(type(spec) == 'table', 'Spec should be a table')
assert(#spec == 5, 'Should have 5 entries (prefix + 4 groups)')

-- Check the spec format
local expected_groups = {
  [','] = 'Remote Operators',
  [',y'] = 'Yank',
  [',d'] = 'Delete',
  [',c'] = 'Change',
  [',v'] = 'Visual',
}

local found_keys = {}
for _, entry in ipairs(spec) do
  assert(type(entry) == 'table', 'Each entry should be a table')
  assert(entry[1], 'Entry should have key at index 1')
  assert(entry.group, "Entry should have 'group' field")
  found_keys[entry[1]] = entry.group
end

-- Verify all expected entries are present
for key, expected_group in pairs(expected_groups) do
  assert(
    found_keys[key] == expected_group,
    string.format(
      "Expected group '%s' for key '%s', got '%s'",
      expected_group,
      key,
      found_keys[key] or 'nil'
    )
  )
end

print('✓ which-key integration using new spec format correctly')
print('✓ All 5 group entries present with correct format')
print('Results: 2/2 tests passed')
print('✓ All tests passed!')
