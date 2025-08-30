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

print('Testing text object discovery methods...')
print('')

-- Method 1: Check operator-pending mappings
test('Discover via operator-pending mappings', function()
  local op_maps = vim.api.nvim_get_keymap('o')
  local text_objects = {}

  for _, map in ipairs(op_maps) do
    local lhs = map.lhs
    if lhs and #lhs >= 2 then
      local first = lhs:sub(1, 1)
      if first == 'i' or first == 'a' then
        text_objects[lhs] = true
        print(string.format('    Found: %s -> %s', lhs, map.rhs or 'native'))
      end
    end
  end

  -- In minimal environment, we might not have many mappings
  -- Just print what we found
  print(string.format('    Found %d mapped text objects', vim.tbl_count(text_objects)))
end)

-- Method 2: Check visual mode mappings
test('Discover via visual mode mappings', function()
  local vis_maps = vim.api.nvim_get_keymap('x')
  local text_objects = {}

  for _, map in ipairs(vis_maps) do
    local lhs = map.lhs
    if lhs and #lhs >= 2 then
      local first = lhs:sub(1, 1)
      if first == 'i' or first == 'a' then
        text_objects[lhs] = true
      end
    end
  end

  print(string.format('    Found %d visual mode text objects', vim.tbl_count(text_objects)))
end)

-- Method 3: Test if a text object works by trying to use it
test('Test built-in text objects by execution', function()
  -- Create a test buffer with content
  vim.cmd('enew!')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    'word "quoted text" more',
    '(parentheses content)',
    '{braces content}',
  })

  local function test_text_object(obj)
    -- Save position
    local save_pos = vim.api.nvim_win_get_cursor(0)

    -- Try to use the text object
    local ok = pcall(function()
      vim.cmd('normal! 1G0') -- Go to start
      vim.cmd('normal! v' .. obj) -- Visual select with text object
      vim.cmd('normal! \027') -- Escape
    end)

    -- Restore position
    vim.api.nvim_win_set_cursor(0, save_pos)

    return ok
  end

  local builtins = {
    'iw',
    'aw', -- words
    'i"',
    'a"', -- quotes
    'i(',
    'a(', -- parentheses
    'i{',
    'a{', -- braces
    'ip',
    'ap', -- paragraph
  }

  local working = {}
  for _, obj in ipairs(builtins) do
    if test_text_object(obj) then
      table.insert(working, obj)
    end
  end

  print(string.format('    %d/%d built-in text objects work', #working, #builtins))
  assert(#working > 0, 'Should have working built-in text objects')
end)

-- Method 4: Use vim.fn.mapcheck to verify text object availability
test('Check text objects with mapcheck', function()
  local function has_mapping(keys, mode)
    local result = vim.fn.mapcheck(keys, mode)
    return result ~= ''
  end

  -- Check some known text objects
  local checked = 0
  local found = 0

  for _, obj in ipairs({ 'iw', 'i"', 'i(', 'ip' }) do
    checked = checked + 1
    if has_mapping(obj, 'o') then
      found = found + 1
    end
  end

  print(string.format('    mapcheck found %d/%d', found, checked))
end)

-- Method 5: Get all available text objects by inspecting loaded plugins
test('Discover from loaded plugins', function()
  -- Check if common text object plugins are loaded
  local plugins = {
    ['mini.ai'] = 'mini.ai',
    ['nvim-treesitter'] = 'nvim-treesitter.configs',
    ['nvim-various-textobjs'] = 'various-textobjs',
  }

  local loaded = {}
  for name, module in pairs(plugins) do
    local ok = pcall(require, module)
    if ok then
      table.insert(loaded, name)
    end
  end

  print(string.format('    Found plugins: %s', table.concat(loaded, ', ')))

  -- If mini.ai is loaded, check its configuration
  local ok, mini_ai = pcall(require, 'mini.ai')
  if ok then
    -- mini.ai exposes its text objects
    print('    mini.ai is available')
  end
end)

-- Method 6: Comprehensive discovery
test('Comprehensive text object discovery', function()
  local all_text_objects = {}

  -- Collect from operator-pending mode
  for _, map in ipairs(vim.api.nvim_get_keymap('o')) do
    local lhs = map.lhs
    if lhs and #lhs >= 2 and (lhs:sub(1, 1) == 'i' or lhs:sub(1, 1) == 'a') then
      all_text_objects[lhs] = { source = 'mapping', mode = 'o' }
    end
  end

  -- Collect from visual mode
  for _, map in ipairs(vim.api.nvim_get_keymap('x')) do
    local lhs = map.lhs
    if lhs and #lhs >= 2 and (lhs:sub(1, 1) == 'i' or lhs:sub(1, 1) == 'a') then
      if not all_text_objects[lhs] then
        all_text_objects[lhs] = { source = 'mapping', mode = 'x' }
      end
    end
  end

  -- Test built-ins that might not show in mappings
  local builtin_tests = {
    'iw',
    'aw',
    'iW',
    'aW',
    'is',
    'as',
    'ip',
    'ap',
    'i"',
    'a"',
    "i'",
    "a'",
    'i`',
    'a`',
    'i(',
    'a(',
    'i)',
    'a)',
    'ib',
    'ab',
    'i[',
    'a[',
    'i]',
    'a]',
    'i{',
    'a{',
    'i}',
    'a}',
    'iB',
    'aB',
    'i<',
    'a<',
    'i>',
    'a>',
    'it',
    'at',
  }

  for _, obj in ipairs(builtin_tests) do
    if not all_text_objects[obj] then
      -- Test if it works
      local ok = pcall(function()
        vim.cmd('normal! v' .. obj .. '\027')
      end)
      if ok then
        all_text_objects[obj] = { source = 'builtin', mode = 'ox' }
      end
    end
  end

  local count = vim.tbl_count(all_text_objects)
  print(string.format('    Total discovered: %d text objects', count))

  -- Categorize them
  local by_prefix = { i = {}, a = {} }
  for obj, _ in pairs(all_text_objects) do
    local prefix = obj:sub(1, 1)
    local suffix = obj:sub(2)
    if by_prefix[prefix] then
      table.insert(by_prefix[prefix], suffix)
    end
  end

  print(string.format('    Inner objects: %d', #by_prefix.i))
  print(string.format('    Around objects: %d', #by_prefix.a))

  assert(count > 10, 'Should discover at least 10 text objects')
end)

print('')
print(string.format('Results: %d/%d tests passed', tests_passed, tests_total))

if tests_passed == tests_total then
  print('✓ All text object discovery tests passed!')
  vim.cmd('qa!')
else
  print('✗ Some tests failed')
  vim.cmd('cq')
end
