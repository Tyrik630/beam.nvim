#!/usr/bin/env nvim -l
-- Tests for search_transform module

-- Add beam.nvim to runtime path
vim.opt.runtimepath:append(vim.fn.getcwd())

local search_transform = require('beam.search_transform')

local test_count = 0
local pass_count = 0
local fail_count = 0

local function test(name, fn)
  test_count = test_count + 1
  local ok, err = pcall(fn)
  if ok then
    pass_count = pass_count + 1
    print(string.format('  ✓ %s', name))
  else
    fail_count = fail_count + 1
    print(string.format('  ✗ %s: %s', name, err))
  end
end

local function assert_equals(expected, actual)
  if expected ~= actual then
    error(string.format('Expected %q, got %q', expected, actual))
  end
end

local function assert_true(value)
  if not value then
    error(string.format('Expected true, got %s', tostring(value)))
  end
end

local function assert_false(value)
  if value then
    error(string.format('Expected false, got %s', tostring(value)))
  end
end

local function assert_nil(value)
  if value ~= nil then
    error(string.format('Expected nil, got %s', tostring(value)))
  end
end

print('Running search_transform tests...')

-- Configuration for tests
local config = { smart_highlighting = true }
local config_disabled = { smart_highlighting = false }

-- Test has_constraints
test('has_constraints returns true for quotes', function()
  assert_true(search_transform.has_constraints('i"'))
  assert_true(search_transform.has_constraints('a"'))
  assert_true(search_transform.has_constraints("i'"))
  assert_true(search_transform.has_constraints('i`'))
end)

test('has_constraints returns true for brackets', function()
  assert_true(search_transform.has_constraints('i{'))
  assert_true(search_transform.has_constraints('i('))
  assert_true(search_transform.has_constraints('i['))
  assert_true(search_transform.has_constraints('i<'))
end)

test('has_constraints returns true for HTML tags', function()
  assert_true(search_transform.has_constraints('it'))
  assert_true(search_transform.has_constraints('at'))
end)

test('has_constraints returns true for block comments', function()
  assert_true(search_transform.has_constraints('iC'))
  assert_true(search_transform.has_constraints('aC'))
end)

test('has_constraints returns true for alternative syntax', function()
  assert_true(search_transform.has_constraints('ib')) -- alternative for i(
  assert_true(search_transform.has_constraints('ab')) -- alternative for a(
  assert_true(search_transform.has_constraints('iB')) -- alternative for i{
  assert_true(search_transform.has_constraints('aB')) -- alternative for a{
  assert_true(search_transform.has_constraints('iq')) -- alternative for i"
  assert_true(search_transform.has_constraints('aq')) -- alternative for a"
end)

test('has_constraints returns false for word/paragraph', function()
  assert_false(search_transform.has_constraints('iw'))
  assert_false(search_transform.has_constraints('ip'))
  assert_false(search_transform.has_constraints('is'))
end)

-- Test transform_search_pattern for quotes
test('transforms pattern for double quotes', function()
  local result = search_transform.transform_search_pattern('test', 'i"', config)
  assert_equals([[\v"[^"]*\zstest\ze[^"]*"]], result)
end)

test('transforms pattern for single quotes', function()
  local result = search_transform.transform_search_pattern('test', "i'", config)
  assert_equals([[\v'[^']*\zstest\ze[^']*']], result)
end)

test('transforms pattern for backticks', function()
  local result = search_transform.transform_search_pattern('test', 'i`', config)
  assert_equals([[\v`[^`]*\zstest\ze[^`]*`]], result)
end)

test('transforms pattern for around quotes', function()
  local result = search_transform.transform_search_pattern('test', 'a"', config)
  assert_equals([[\v"\zs[^"]*test[^"]*\ze"]], result)
end)

-- Test transform_search_pattern for brackets
test('transforms pattern for curly braces', function()
  local result = search_transform.transform_search_pattern('test', 'i{', config)
  assert_equals([[\v\{[^}]*\zstest\ze[^}]*\}]], result)
end)

test('transforms pattern for parentheses', function()
  local result = search_transform.transform_search_pattern('test', 'i(', config)
  assert_equals([[\v\([^)]*\zstest\ze[^)]*\)]], result)
end)

test('transforms pattern for square brackets', function()
  local result = search_transform.transform_search_pattern('test', 'i[', config)
  assert_equals('\\v\\[[^\\]]*\\zstest\\ze[^\\]]*\\]', result)
end)

test('transforms pattern for angle brackets', function()
  local result = search_transform.transform_search_pattern('test', 'i<', config)
  assert_equals([[\v\<[^>]*\zstest\ze[^>]*\>]], result)
end)

-- Test HTML/XML tags
test('transforms pattern for inside tags', function()
  local result = search_transform.transform_search_pattern('test', 'it', config)
  assert_equals([[\v\<\w+[^>]*\>\zstest\ze\</\w+\>]], result)
end)

test('transforms pattern for around tags', function()
  local result = search_transform.transform_search_pattern('test', 'at', config)
  assert_equals([[\v\<\w+[^>]*\>test\</\w+\>]], result)
end)

-- Test block comments
test('transforms pattern for inside block comments', function()
  local result = search_transform.transform_search_pattern('test', 'iC', config)
  assert_equals([[\v/\*\zs%(.*\n)*test%(.*\n)*\ze\*/]], result)
end)

test('transforms pattern for around block comments', function()
  local result = search_transform.transform_search_pattern('test', 'aC', config)
  assert_equals([[\v/\*%(.*\n)*test%(.*\n)*\*/]], result)
end)

-- Test configuration behavior
test('returns original when smart_highlighting disabled', function()
  local result = search_transform.transform_search_pattern('test', 'i"', config_disabled)
  assert_equals('test', result)
end)

test('returns original when config is nil', function()
  local result = search_transform.transform_search_pattern('test', 'i"', nil)
  assert_equals('test', result)
end)

test('returns original for unconstrained text objects', function()
  local result = search_transform.transform_search_pattern('test', 'iw', config)
  assert_equals('test', result)
end)

-- Test get_delimiter_info
test('returns delimiter info for quotes', function()
  local info = search_transform.get_delimiter_info('i"')
  assert_equals('"', info.open)
  assert_equals('"', info.close)
end)

test('returns delimiter info for brackets', function()
  local info = search_transform.get_delimiter_info('i{')
  assert_equals('{', info.open)
  assert_equals('}', info.close)
end)

test('returns nil for unconstrained objects', function()
  local info = search_transform.get_delimiter_info('iw')
  assert_nil(info)
end)

-- Test alternative bracket syntax (ib/ab for parentheses)
test('transforms pattern for alternative parentheses inside', function()
  local result = search_transform.transform_search_pattern('test', 'ib', config)
  assert_equals([[\v\([^)]*\zstest\ze[^)]*\)]], result)
end)

test('transforms pattern for alternative parentheses around', function()
  local result = search_transform.transform_search_pattern('test', 'ab', config)
  assert_equals([[\v\(\zs[^)]*test[^)]*\ze\)]], result)
end)

-- Test alternative brace syntax (iB/aB)
test('transforms pattern for alternative brace inside', function()
  local result = search_transform.transform_search_pattern('test', 'iB', config)
  assert_equals([[\v\{[^}]*\zstest\ze[^}]*\}]], result)
end)

test('transforms pattern for alternative brace around', function()
  local result = search_transform.transform_search_pattern('test', 'aB', config)
  assert_equals([[\v\{\zs[^}]*test[^}]*\ze\}]], result)
end)

-- Test alternative quote syntax (iq/aq for double quotes)
test('transforms pattern for alternative quote inside', function()
  local result = search_transform.transform_search_pattern('test', 'iq', config)
  assert_equals([[\v"[^"]*\zstest\ze[^"]*"]], result)
end)

test('transforms pattern for alternative quote around', function()
  local result = search_transform.transform_search_pattern('test', 'aq', config)
  assert_equals([[\v"\zs[^"]*test[^"]*\ze"]], result)
end)

-- Test custom constraint registration
test('registers custom constraints', function()
  local custom = {
    delim_open = '<<',
    delim_close = '>>',
    wrap_pattern = function(search)
      return '\\v<<\\zs' .. search .. '\\ze>>'
    end,
  }

  search_transform.register_custom_constraint('ix', custom)
  assert_true(search_transform.has_constraints('ix'))

  local result = search_transform.transform_search_pattern('test', 'ix', config)
  assert_equals('\\v<<\\zstest\\ze>>', result)
end)

test('rejects invalid constraints', function()
  search_transform.register_custom_constraint('iy', 'invalid')
  assert_false(search_transform.has_constraints('iy'))

  search_transform.register_custom_constraint('iz', { delim_open = '[[' })
  assert_false(search_transform.has_constraints('iz'))
end)

-- Test special characters
test('preserves special regex characters', function()
  local result = search_transform.transform_search_pattern('test.*', 'i"', config)
  assert_equals([[\v"[^"]*\zstest.*\ze[^"]*"]], result)
end)

test('handles empty search pattern', function()
  local result = search_transform.transform_search_pattern('', 'i"', config)
  assert_equals([[\v"[^"]*\zs\ze[^"]*"]], result)
end)

-- Summary
print(string.format('\nResults: %d/%d tests passed', pass_count, test_count))
if fail_count > 0 then
  print('✗ Some tests failed')
  os.exit(1)
else
  print('✓ All tests passed!')
  os.exit(0)
end
