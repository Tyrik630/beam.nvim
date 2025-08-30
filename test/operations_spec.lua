describe('beam operations', function()
  local beam

  local function set_buffer(text, pos)
    local lines = vim.split(vim.trim(text), '\n')
    lines = vim.tbl_map(function(line)
      return vim.trim(line)
    end, lines)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, pos or { 1, 0 })
  end

  local function get_buffer()
    return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
  end

  local function get_register(reg)
    return vim.fn.getreg(reg or '"')
  end

  local function get_cursor()
    return vim.api.nvim_win_get_cursor(0)
  end

  before_each(function()
    -- Clear any previous module loads
    package.loaded['beam'] = nil
    package.loaded['beam.config'] = nil
    package.loaded['beam.operators'] = nil
    package.loaded['beam.mappings'] = nil

    -- Clear registers
    vim.fn.setreg('"', '')
    vim.fn.setreg('0', '')

    -- Setup beam
    beam = require('beam')
    beam.setup({ prefix = ',' })

    -- Create a fresh buffer
    vim.cmd('enew!')
  end)

  describe('yank operations', function()
    it('should yank inside quotes without moving cursor', function()
      set_buffer('foo "bar" baz', { 1, 0 })
      local initial_pos = get_cursor()

      -- Simulate the operation
      _G.BeamYankSearchSetup('i"')
      -- Simulate finding and executing at position
      vim.api.nvim_win_set_cursor(0, { 1, 5 }) -- Move to inside quotes
      _G.BeamSearchOperator('char')

      -- Check that content was yanked
      assert.equals('bar', get_register())
      -- Check cursor returned to original position
      assert.are.same(initial_pos, get_cursor())
    end)

    it('should yank around word', function()
      set_buffer('foo bar baz', { 1, 0 })
      local initial_pos = get_cursor()

      _G.BeamYankSearchSetup('aw')
      vim.api.nvim_win_set_cursor(0, { 1, 4 }) -- Move to 'bar'
      _G.BeamSearchOperator('char')

      assert.equals('bar ', get_register())
      assert.are.same(initial_pos, get_cursor())
    end)

    it('should yank inside parentheses', function()
      set_buffer('foo(bar, baz) end', { 1, 0 })

      _G.BeamYankSearchSetup('i(')
      vim.api.nvim_win_set_cursor(0, { 1, 4 })
      _G.BeamSearchOperator('char')

      assert.equals('bar, baz', get_register())
    end)

    it('should yank inside block', function()
      set_buffer(
        [[
        function test()
          local x = 1
          return x
        end
      ]],
        { 1, 0 }
      )

      _G.BeamYankSearchSetup('iB')
      vim.api.nvim_win_set_cursor(0, { 2, 2 })
      _G.BeamSearchOperator('line')

      local yanked = get_register()
      assert.is_truthy(yanked:match('local x = 1'))
      assert.is_truthy(yanked:match('return x'))
    end)
  end)

  describe('delete operations', function()
    it('should delete inside quotes without moving cursor', function()
      set_buffer('foo "bar" baz', { 1, 0 })
      local initial_pos = get_cursor()

      _G.BeamDeleteSearchSetup('i"')
      vim.api.nvim_win_set_cursor(0, { 1, 5 })
      _G.BeamSearchOperator('char')

      assert.equals('foo "" baz', get_buffer())
      assert.are.same(initial_pos, get_cursor())
    end)

    it('should delete around paragraph', function()
      set_buffer(
        [[
        first line
        
        second paragraph
        with multiple lines
        
        third paragraph
      ]],
        { 1, 0 }
      )

      _G.BeamDeleteSearchSetup('ap')
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
      _G.BeamSearchOperator('line')

      local result = get_buffer()
      assert.is_falsy(result:match('second paragraph'))
      assert.is_falsy(result:match('with multiple lines'))
      assert.is_truthy(result:match('first line'))
      assert.is_truthy(result:match('third paragraph'))
    end)
  end)

  describe('change operations', function()
    it('should change inside quotes and move cursor', function()
      set_buffer('foo "bar" baz', { 1, 0 })

      _G.BeamChangeSearchSetup('i"')
      vim.api.nvim_win_set_cursor(0, { 1, 5 })
      _G.BeamSearchOperator('char')

      -- Should delete content and enter insert mode
      assert.equals('foo "" baz', get_buffer())
      -- Cursor should be inside the quotes
      local pos = get_cursor()
      assert.equals(1, pos[1])
      assert.equals(5, pos[2]) -- Inside the empty quotes
    end)

    it('should change inside word', function()
      set_buffer('fooBar baz', { 1, 0 })

      _G.BeamChangeSearchSetup('iw')
      vim.api.nvim_win_set_cursor(0, { 1, 3 })
      _G.BeamSearchOperator('char')

      assert.equals(' baz', get_buffer())
      -- Cursor should be at beginning where word was
      local pos = get_cursor()
      assert.equals(1, pos[1])
      assert.equals(0, pos[2])
    end)
  end)

  describe('visual operations', function()
    it('should select inside brackets and move cursor', function()
      set_buffer('foo [bar] baz', { 1, 0 })

      _G.BeamVisualSearchSetup('i[')
      vim.api.nvim_win_set_cursor(0, { 1, 5 })
      _G.BeamSearchOperator('char')

      -- Check visual mode is active
      local mode = vim.fn.mode()
      assert.equals('v', mode)

      -- Check selection (simulate getting selected text)
      vim.cmd('normal! y')
      assert.equals('bar', get_register())
    end)
  end)

  describe('line operations', function()
    it('should yank entire line with ,Y', function()
      set_buffer(
        [[
        first line
        second line
        third line
      ]],
        { 1, 0 }
      )

      -- This would be triggered by ,Y mapping
      _G.BeamYankSearchSetup('_') -- _ for line
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      _G.BeamSearchOperator('line')

      assert.equals('second line\n', get_register())
    end)

    it('should delete entire line with ,D', function()
      set_buffer(
        [[
        first line
        second line
        third line
      ]],
        { 1, 0 }
      )

      _G.BeamDeleteSearchSetup('_')
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      _G.BeamSearchOperator('line')

      local result = get_buffer()
      assert.is_falsy(result:match('second line'))
      assert.is_truthy(result:match('first line'))
      assert.is_truthy(result:match('third line'))
    end)
  end)

  describe('text object combinations', function()
    local objects_to_test = {
      -- Quotes and strings
      { obj = 'i"', text = 'foo "bar" baz', pos = { 1, 5 }, expected = 'bar' },
      { obj = 'a"', text = 'foo "bar" baz', pos = { 1, 5 }, expected = '"bar"' },
      { obj = "i'", text = "foo 'bar' baz", pos = { 1, 5 }, expected = 'bar' },
      { obj = "a'", text = "foo 'bar' baz", pos = { 1, 5 }, expected = "'bar'" },
      { obj = 'i`', text = 'foo `bar` baz', pos = { 1, 5 }, expected = 'bar' },
      { obj = 'a`', text = 'foo `bar` baz', pos = { 1, 5 }, expected = '`bar`' },

      -- Brackets
      { obj = 'i(', text = 'foo(bar)baz', pos = { 1, 4 }, expected = 'bar' },
      { obj = 'a(', text = 'foo(bar)baz', pos = { 1, 4 }, expected = '(bar)' },
      { obj = 'i[', text = 'foo[bar]baz', pos = { 1, 4 }, expected = 'bar' },
      { obj = 'a[', text = 'foo[bar]baz', pos = { 1, 4 }, expected = '[bar]' },
      { obj = 'i{', text = 'foo{bar}baz', pos = { 1, 4 }, expected = 'bar' },
      { obj = 'a{', text = 'foo{bar}baz', pos = { 1, 4 }, expected = '{bar}' },
      { obj = 'i<', text = 'foo<bar>baz', pos = { 1, 4 }, expected = 'bar' },
      { obj = 'a<', text = 'foo<bar>baz', pos = { 1, 4 }, expected = '<bar>' },

      -- Words
      { obj = 'iw', text = 'foo bar baz', pos = { 1, 4 }, expected = 'bar' },
      { obj = 'aw', text = 'foo bar baz', pos = { 1, 4 }, expected = 'bar ' },
      { obj = 'iW', text = 'foo-bar baz', pos = { 1, 4 }, expected = 'foo-bar' },
      { obj = 'aW', text = 'foo-bar baz', pos = { 1, 4 }, expected = 'foo-bar ' },

      -- Markdown code blocks (im/am) - these require multi-line text
    }

    for _, test in ipairs(objects_to_test) do
      it(string.format('should yank %s correctly', test.obj), function()
        set_buffer(test.text, { 1, 0 })

        _G.BeamYankSearchSetup(test.obj)
        vim.api.nvim_win_set_cursor(0, test.pos)
        _G.BeamSearchOperator('char')

        assert.equals(
          test.expected,
          get_register(),
          string.format('Failed for text object %s', test.obj)
        )
      end)
    end
  end)
end)
