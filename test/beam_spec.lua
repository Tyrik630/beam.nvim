describe('beam.nvim', function()
  local beam

  before_each(function()
    -- Clear any previous module loads
    package.loaded['beam'] = nil
    package.loaded['beam.config'] = nil
    package.loaded['beam.operators'] = nil
    package.loaded['beam.mappings'] = nil

    -- Clear any existing keymaps with our prefix
    if vim and vim.api and vim.api.nvim_get_keymap then
      local keymaps = vim.api.nvim_get_keymap('n')
      for _, map in ipairs(keymaps) do
        if map.lhs:match('^,') then
          pcall(vim.keymap.del, 'n', map.lhs)
        end
      end
    end

    -- Clear any existing global functions
    operators.BeamSearchOperator = nil
    operators.BeamSearchOperatorPending = nil
    operators.BeamExecuteSearchOperator = nil
    operators.BeamYankSearchSetup = nil
    operators.BeamDeleteSearchSetup = nil
    operators.BeamChangeSearchSetup = nil
    operators.BeamVisualSearchSetup = nil

    beam = require('beam')
  end)

  describe('setup', function()
    it('should load with default configuration', function()
      beam.setup()
      local config = beam.get_config()
      assert.equals(',', config.prefix)
      assert.equals(150, config.visual_feedback_duration)
      assert.equals(true, config.clear_highlight)
      assert.equals(500, config.clear_highlight_delay)
    end)

    it('should accept custom configuration', function()
      beam.setup({
        prefix = ';',
        visual_feedback_duration = 200,
        clear_highlight = false,
      })
      local config = beam.get_config()
      assert.equals(';', config.prefix)
      assert.equals(200, config.visual_feedback_duration)
      assert.equals(false, config.clear_highlight)
    end)

    it('should merge custom text objects', function()
      beam.setup({
        custom_text_objects = {
          ['x'] = 'custom object',
        },
      })
      local config_module = require('beam.config')
      assert.equals('custom object', config_module.text_objects['x'])
    end)
  end)

  describe('text object registration', function()
    it('should register single text object', function()
      beam.setup()
      beam.register_text_object('z', 'test object')
      local config_module = require('beam.config')
      assert.equals('test object', config_module.text_objects['z'])
    end)

    it('should register multiple text objects', function()
      beam.setup()
      beam.register_text_objects({
        ['x'] = 'object x',
        ['y'] = 'object y',
      })
      local config_module = require('beam.config')
      assert.equals('object x', config_module.text_objects['x'])
      assert.equals('object y', config_module.text_objects['y'])
    end)
  end)

  describe('operator functions', function()
    it('should create global operator functions', function()
      beam.setup()
      assert.is_not_nil(operators.BeamSearchOperator)
      assert.is_not_nil(operators.BeamExecuteSearchOperator)
      assert.is_not_nil(operators.BeamYankSearchSetup)
      assert.is_not_nil(operators.BeamDeleteSearchSetup)
      assert.is_not_nil(operators.BeamChangeSearchSetup)
      assert.is_not_nil(operators.BeamVisualSearchSetup)
    end)

    it('should set up pending state correctly', function()
      beam.setup()
      local result = operators.BeamYankSearchSetup('i"')
      assert.equals('/', result)
      assert.equals('yank', operators.BeamSearchOperatorPending.action)
      assert.equals('i"', operators.BeamSearchOperatorPending.textobj)
      assert.is_not_nil(operators.BeamSearchOperatorPending.saved_pos_for_yank)
    end)

    it('should handle delete setup', function()
      beam.setup()
      local result = operators.BeamDeleteSearchSetup('ap')
      assert.equals('/', result)
      assert.equals('delete', operators.BeamSearchOperatorPending.action)
      assert.equals('ap', operators.BeamSearchOperatorPending.textobj)
      assert.is_not_nil(operators.BeamSearchOperatorPending.saved_pos_for_yank)
    end)

    it('should handle change setup without saving position', function()
      beam.setup()
      local result = operators.BeamChangeSearchSetup('iw')
      assert.equals('/', result)
      assert.equals('change', operators.BeamSearchOperatorPending.action)
      assert.equals('iw', operators.BeamSearchOperatorPending.textobj)
      assert.is_nil(operators.BeamSearchOperatorPending.saved_pos_for_yank)
    end)
  end)

  describe('mappings', function()
    it('should create keymaps with configured prefix', function()
      beam.setup({ prefix = ',' })

      -- Get actual keymaps from Neovim
      local keymaps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ',yi"' then
          found = true
          break
        end
      end
      assert.is_true(found, 'Should create ,yi" mapping')
    end)

    it('should create line operator mappings', function()
      beam.setup({ prefix = ',' })

      -- Get actual keymaps from Neovim
      local keymaps = vim.api.nvim_get_keymap('n')
      local found_Y = false
      local found_D = false
      for _, map in ipairs(keymaps) do
        if map.lhs == ',Y' then
          found_Y = true
        end
        if map.lhs == ',D' then
          found_D = true
        end
      end
      assert.is_true(found_Y, 'Should create ,Y mapping')
      assert.is_true(found_D, 'Should create ,D mapping')
    end)
  end)

  describe('statusline indicator', function()
    it('should set indicator during operation', function()
      beam.setup()
      operators.BeamYankSearchSetup('i"')
      assert.equals('yank[i"]', vim.g.beam_search_operator_indicator)
    end)
  end)
end)
