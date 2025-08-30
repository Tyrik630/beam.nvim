#!/usr/bin/env -S nvim -l

-- Test custom text object registration
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

print('Testing custom text object registration...')
print('')

-- Test 1: String format (should NOT create actual text object)
test("String format doesn't create text object", function()
  require('beam').setup({
    prefix = ',',
    custom_text_objects = {
      ['F'] = 'function (treesitter)',
    },
  })

  -- Check if mappings were created (they shouldn't be)
  local keymaps_o = vim.api.nvim_get_keymap('o')
  local found_iF = false
  for _, map in ipairs(keymaps_o) do
    if map.lhs == 'iF' then
      found_iF = true
      break
    end
  end

  assert(not found_iF, 'String format should NOT create actual text object mappings')
end)

-- Test 2: Table format with select function (should create text object)
test('Table format creates text object', function()
  vim.cmd('mapclear') -- Clear previous mappings

  require('beam').setup({
    prefix = ',',
    custom_text_objects = {
      ['r'] = {
        desc = 'Ruby block',
        select = function(inclusive)
          if inclusive then
            vim.cmd('normal! vaB')
          else
            vim.cmd('normal! viB')
          end
        end,
      },
    },
  })

  -- Check if mappings were created
  local keymaps_o = vim.api.nvim_get_keymap('o')
  local found_ir = false
  local found_ar = false

  for _, map in ipairs(keymaps_o) do
    if map.lhs == 'ir' then
      found_ir = true
    end
    if map.lhs == 'ar' then
      found_ar = true
    end
  end

  assert(found_ir, "Should create 'ir' mapping in operator-pending mode")
  assert(found_ar, "Should create 'ar' mapping in operator-pending mode")
end)

-- Test 3: Default markdown text objects
test('Default markdown text objects (im/am) are registered', function()
  vim.cmd('mapclear')

  require('beam').setup({
    prefix = ',',
    enable_default_text_objects = true,
  })

  local keymaps_o = vim.api.nvim_get_keymap('o')
  local found_im = false
  local found_am = false

  for _, map in ipairs(keymaps_o) do
    if map.lhs == 'im' then
      found_im = true
    end
    if map.lhs == 'am' then
      found_am = true
    end
  end

  assert(found_im, "Should create 'im' mapping for markdown code blocks")
  assert(found_am, "Should create 'am' mapping for markdown code blocks")
end)

-- Test 4: Test actual operation with custom text object
test('Custom text object works with beam operations', function()
  vim.cmd('enew!')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { '{', '  content', '}' })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })

  -- The 'r' text object should be available for beam operations
  -- even though we can't easily test the full flow here
  _G.BeamYankSearchSetup('ir')

  assert(_G.BeamSearchOperatorPending, 'Should create pending state')
  assert(_G.BeamSearchOperatorPending.textobj == 'ir', 'Should use custom text object')
end)

print('')
print(string.format('Results: %d/%d tests passed', tests_passed, tests_total))

if tests_passed == tests_total then
  print('✓ All custom text object tests passed!')
  vim.cmd('qa!')
else
  print('✗ Some tests failed')
  vim.cmd('cq')
end
