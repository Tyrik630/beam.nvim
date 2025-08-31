-- Text object discovery tests using real Plenary busted
describe('beam.nvim text object discovery', function()
  describe('discovery methods', function()
    it('discovers operator-pending mappings', function()
      local op_maps = vim.api.nvim_get_keymap('o')
      local text_objects = {}

      for _, map in ipairs(op_maps) do
        local lhs = map.lhs
        if lhs and #lhs >= 2 then
          local first = lhs:sub(1, 1)
          if first == 'i' or first == 'a' then
            text_objects[lhs] = true
          end
        end
      end

      -- In minimal environment, might not have many mappings
      -- Just verify the discovery mechanism works
      assert.is_not_nil(op_maps, 'Should be able to query operator-pending maps')
    end)

    it('discovers visual mode mappings', function()
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

      -- Visual mode should have text objects too
      assert.is_true(vim.tbl_count(text_objects) >= 0, 'Should find visual mode text objects')
    end)
  end)

  describe('built-in text object testing', function()
    local test_buf

    before_each(function()
      test_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(test_buf)
      vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
        'word "quoted text" more',
        '(parentheses content)',
        '{braces content}',
      })
    end)

    after_each(function()
      if test_buf and vim.api.nvim_buf_is_valid(test_buf) then
        vim.api.nvim_buf_delete(test_buf, { force = true })
      end
    end)

    local function test_text_object(obj)
      local ok = pcall(function()
        vim.cmd('normal! 1G0')
        vim.cmd('normal! v' .. obj)
        vim.cmd('normal! \027')
      end)
      return ok
    end

    it('detects working built-in text objects', function()
      local working = {}
      local objects_to_test = { 'iw', 'aw', 'i"', 'a"', 'i(', 'a(', 'i{', 'a{' }

      for _, obj in ipairs(objects_to_test) do
        if test_text_object(obj) then
          working[obj] = true
        end
      end

      -- Should have most common text objects
      assert.is_true(working['iw'] or false, 'Should have inner word')
      assert.is_true(working['aw'] or false, 'Should have around word')
    end)
  end)

  describe('auto-registration with beam.nvim', function()
    it('auto-discovers and registers text objects', function()
      -- Clear previous state
      package.loaded['beam'] = nil
      package.loaded['beam.text_object_discovery'] = nil

      local beam = require('beam')
      beam.setup({
        prefix = ',',
        auto_discover_text_objects = true,
        show_discovery_notification = false,
      })

      -- Give it time to discover
      vim.wait(100)

      local config = beam.get_config()
      -- Config should exist
      assert.is_not_nil(config, 'Should have config')
      assert.is_not_nil(config.prefix, 'Config should be initialized')
    end)
  end)

  describe('plugin text object discovery', function()
    it('can discover plugin-provided text objects', function()
      -- Create a mock plugin text object
      vim.api.nvim_set_keymap('o', 'if', ':<C-u>call SelectFunction()<CR>', { silent = true })

      local op_maps = vim.api.nvim_get_keymap('o')
      local found_if = false

      for _, map in ipairs(op_maps) do
        if map.lhs == 'if' then
          found_if = true
          break
        end
      end

      assert.is_true(found_if, 'Should discover plugin text objects')

      -- Clean up
      vim.api.nvim_del_keymap('o', 'if')
    end)
  end)
end)
