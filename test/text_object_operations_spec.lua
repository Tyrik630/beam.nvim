-- Tests for all text object operations using Plenary busted
local beam = require('beam')
local operators = require('beam.operators')

describe('beam.nvim text object operations', function()
  before_each(function()
    beam.setup({
      prefix = ',',
      visual_feedback_duration = 10,
      enable_default_text_objects = true,
    })

    -- Suppress visual mode and line change messages
    vim.o.showcmd = false
    vim.o.showmode = false
    vim.o.report = 999
  end)

  -- Helper function to set buffer content
  local function set_buffer(lines)
    vim.cmd('enew!')
    if type(lines) == 'string' then
      lines = { lines }
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
  end

  -- Helper to perform beam operation
  local function perform_beam_operation(action, textobj, target_pos)
    local initial_pos = vim.fn.getpos('.')

    -- Setup the operation
    if action == 'yank' then
      operators.BeamYankSearchSetup(textobj)
    elseif action == 'delete' then
      operators.BeamDeleteSearchSetup(textobj)
    elseif action == 'change' then
      operators.BeamChangeSearchSetup(textobj)
    elseif action == 'visual' then
      operators.BeamVisualSearchSetup(textobj)
    end

    -- Move to target position
    if target_pos then
      vim.api.nvim_win_set_cursor(0, target_pos)
    end

    -- Copy pending state to global vars
    if operators.BeamSearchOperatorPending then
      vim.g.beam_search_operator_pattern = ''
      vim.g.beam_search_operator_textobj = operators.BeamSearchOperatorPending.textobj
      vim.g.beam_search_operator_action = operators.BeamSearchOperatorPending.action
      vim.g.beam_search_operator_saved_pos = operators.BeamSearchOperatorPending.saved_pos_for_yank
    end

    -- Execute the operation
    operators.BeamSearchOperator('char')

    -- For change operation, process the feedkeys queue
    -- Note: 'x' flag will auto-exit insert mode
    if action == 'change' then
      vim.api.nvim_feedkeys('', 'x', false)
    end

    return initial_pos
  end

  describe('quote text objects', function()
    it('yanks inside double quotes', function()
      set_buffer('foo "bar" baz')
      perform_beam_operation('yank', 'i"', { 1, 5 })
      assert.equals('bar', vim.fn.getreg('"'))
    end)

    it('deletes inside double quotes', function()
      set_buffer('foo "bar" baz')
      perform_beam_operation('delete', 'i"', { 1, 5 })
      assert.equals('foo "" baz', vim.api.nvim_get_current_line())
    end)

    it('yanks around double quotes', function()
      set_buffer('foo "bar" baz')
      perform_beam_operation('yank', 'a"', { 1, 5 })
      local yanked = vim.fn.getreg('"')
      assert.is_true(yanked == '"bar"' or yanked == '"bar" ')
    end)

    it('yanks inside single quotes', function()
      set_buffer("foo 'bar' baz")
      perform_beam_operation('yank', "i'", { 1, 5 })
      assert.equals('bar', vim.fn.getreg('"'))
    end)

    it('deletes inside single quotes', function()
      set_buffer("foo 'bar' baz")
      perform_beam_operation('delete', "i'", { 1, 5 })
      assert.equals("foo '' baz", vim.api.nvim_get_current_line())
    end)

    it('yanks inside backticks', function()
      set_buffer('foo `bar` baz')
      perform_beam_operation('yank', 'i`', { 1, 5 })
      assert.equals('bar', vim.fn.getreg('"'))
    end)

    it('deletes inside backticks', function()
      set_buffer('foo `bar` baz')
      perform_beam_operation('delete', 'i`', { 1, 5 })
      assert.equals('foo `` baz', vim.api.nvim_get_current_line())
    end)
  end)

  describe('bracket text objects', function()
    it('yanks inside parentheses', function()
      set_buffer('foo(bar)baz')
      perform_beam_operation('yank', 'i(', { 1, 4 })
      assert.equals('bar', vim.fn.getreg('"'))
    end)

    it('deletes inside parentheses', function()
      set_buffer('foo(bar)baz')
      perform_beam_operation('delete', 'i(', { 1, 4 })
      assert.equals('foo()baz', vim.api.nvim_get_current_line())
    end)

    it('yanks around parentheses', function()
      set_buffer('foo(bar)baz')
      perform_beam_operation('yank', 'a(', { 1, 4 })
      assert.equals('(bar)', vim.fn.getreg('"'))
    end)

    it('deletes around parentheses', function()
      set_buffer('foo(bar)baz')
      perform_beam_operation('delete', 'a(', { 1, 4 })
      assert.equals('foobaz', vim.api.nvim_get_current_line())
    end)

    it('yanks inside square brackets', function()
      set_buffer('foo[bar]baz')
      perform_beam_operation('yank', 'i[', { 1, 4 })
      assert.equals('bar', vim.fn.getreg('"'))
    end)

    it('deletes inside square brackets', function()
      set_buffer('foo[bar]baz')
      perform_beam_operation('delete', 'i[', { 1, 4 })
      assert.equals('foo[]baz', vim.api.nvim_get_current_line())
    end)

    it('yanks inside curly braces', function()
      set_buffer('foo{bar}baz')
      perform_beam_operation('yank', 'i{', { 1, 4 })
      assert.equals('bar', vim.fn.getreg('"'))
    end)

    it('deletes inside curly braces', function()
      set_buffer('foo{bar}baz')
      perform_beam_operation('delete', 'i{', { 1, 4 })
      assert.equals('foo{}baz', vim.api.nvim_get_current_line())
    end)

    it('yanks around curly braces', function()
      set_buffer('foo{bar}baz')
      perform_beam_operation('yank', 'a{', { 1, 4 })
      assert.equals('{bar}', vim.fn.getreg('"'))
    end)

    it('yanks inside angle brackets', function()
      set_buffer('foo<bar>baz')
      perform_beam_operation('yank', 'i<', { 1, 4 })
      assert.equals('bar', vim.fn.getreg('"'))
    end)

    it('deletes inside angle brackets', function()
      set_buffer('foo<bar>baz')
      perform_beam_operation('delete', 'i<', { 1, 4 })
      assert.equals('foo<>baz', vim.api.nvim_get_current_line())
    end)

    -- Alternative syntax tests
    it('yanks inside parentheses using ib', function()
      set_buffer('foo(bar)baz')
      perform_beam_operation('yank', 'ib', { 1, 4 })
      assert.equals('bar', vim.fn.getreg('"'))
    end)

    it('yanks around parentheses using ab', function()
      set_buffer('foo(bar)baz')
      perform_beam_operation('yank', 'ab', { 1, 4 })
      assert.equals('(bar)', vim.fn.getreg('"'))
    end)

    it('yanks inside curly braces using iB', function()
      set_buffer('foo{bar}baz')
      perform_beam_operation('yank', 'iB', { 1, 4 })
      assert.equals('bar', vim.fn.getreg('"'))
    end)

    it('yanks around curly braces using aB', function()
      set_buffer('foo{bar}baz')
      perform_beam_operation('yank', 'aB', { 1, 4 })
      assert.equals('{bar}', vim.fn.getreg('"'))
    end)
  end)

  describe('word text objects', function()
    it('yanks inside word', function()
      set_buffer('foo bar baz')
      perform_beam_operation('yank', 'iw', { 1, 4 })
      assert.equals('bar', vim.fn.getreg('"'))
    end)

    it('deletes inside word', function()
      set_buffer('foo bar baz')
      perform_beam_operation('delete', 'iw', { 1, 4 })
      assert.equals('foo  baz', vim.api.nvim_get_current_line())
    end)

    it('yanks around word', function()
      set_buffer('foo bar baz')
      perform_beam_operation('yank', 'aw', { 1, 4 })
      local yanked = vim.fn.getreg('"')
      assert.is_true(yanked == 'bar ' or yanked == ' bar')
    end)

    it('deletes around word', function()
      set_buffer('foo bar baz')
      perform_beam_operation('delete', 'aw', { 1, 4 })
      assert.equals('foo baz', vim.api.nvim_get_current_line())
    end)

    it('yanks inside WORD', function()
      set_buffer('foo foo-bar baz')
      perform_beam_operation('yank', 'iW', { 1, 4 })
      assert.equals('foo-bar', vim.fn.getreg('"'))
    end)

    it('deletes inside WORD', function()
      set_buffer('foo foo-bar baz')
      perform_beam_operation('delete', 'iW', { 1, 4 })
      assert.equals('foo  baz', vim.api.nvim_get_current_line())
    end)
  end)

  describe('paragraph text objects', function()
    it('yanks inside paragraph', function()
      set_buffer({ 'first line', 'second line', '', 'third line' })
      perform_beam_operation('yank', 'ip', { 1, 0 })
      local yanked = vim.fn.getreg('"')
      assert.is_true(yanked:match('first line') ~= nil)
      assert.is_true(yanked:match('second line') ~= nil)
    end)

    it('deletes inside paragraph', function()
      set_buffer({ 'first line', 'second line', '', 'third line' })
      perform_beam_operation('delete', 'ip', { 1, 0 })
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equals(2, #lines)
    end)
  end)

  describe('sentence text objects', function()
    it('yanks inside sentence', function()
      set_buffer('First sentence. Second sentence. Third.')
      perform_beam_operation('yank', 'is', { 1, 16 })
      assert.equals('Second sentence.', vim.fn.getreg('"'))
    end)

    it('deletes inside sentence', function()
      set_buffer('First sentence. Second sentence. Third.')
      perform_beam_operation('delete', 'is', { 1, 16 })
      local result = vim.api.nvim_get_current_line()
      assert.is_true(result:match('First sentence.*Third') ~= nil)
    end)
  end)

  describe('cursor position after operations', function()
    it('returns to original position after yank', function()
      set_buffer('foo "bar" baz')
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      perform_beam_operation('yank', 'i"', { 1, 5 })
      local pos = vim.api.nvim_win_get_cursor(0)
      assert.equals(1, pos[1])
      assert.equals(0, pos[2])
    end)

    it('returns to original position after delete', function()
      set_buffer('foo "bar" baz')
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      perform_beam_operation('delete', 'i"', { 1, 5 })
      local pos = vim.api.nvim_win_get_cursor(0)
      assert.equals(1, pos[1])
      assert.equals(0, pos[2]) -- Should return to original position
    end)
  end)

  describe('change operations', function()
    it('sets up change operation correctly', function()
      set_buffer('foo "bar" baz')
      operators.BeamChangeSearchSetup('i"')
      assert.is_not_nil(operators.BeamSearchOperatorPending)
      assert.equals('change', operators.BeamSearchOperatorPending.action)
      assert.equals('i"', operators.BeamSearchOperatorPending.textobj)
      -- Change operations should not save position (cursor moves to target)
      assert.is_nil(operators.BeamSearchOperatorPending.saved_pos_for_yank)
    end)

    it('deletes text object content for change', function()
      set_buffer('foo (bar) baz')
      perform_beam_operation('change', 'i(', { 1, 5 })
      -- Exit insert mode if entered
      vim.cmd('stopinsert')
      -- The change operation should delete the content but leave empty parens
      assert.equals('foo () baz', vim.api.nvim_get_current_line())
    end)

    it('stays at target position after change', function()
      set_buffer('foo "bar" baz')
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      perform_beam_operation('change', 'i"', { 1, 5 })
      vim.cmd('stopinsert')
      local pos = vim.api.nvim_win_get_cursor(0)
      assert.equals(1, pos[1])
      assert.is_true(pos[2] >= 4) -- Should stay at target
    end)
  end)

  describe('visual operations', function()
    it('selects text object visually', function()
      set_buffer('foo "bar" baz')
      perform_beam_operation('visual', 'i"', { 1, 5 })
      assert.equals('v', vim.fn.mode())
      vim.cmd('normal! y')
      assert.equals('bar', vim.fn.getreg('"'))
      vim.cmd('normal! <Esc>')
    end)
  end)

  describe('multiline text objects', function()
    it('handles multiline curly braces', function()
      set_buffer({ 'foo {', '  bar', '  baz', '}' })
      perform_beam_operation('yank', 'i{', { 2, 2 })
      local yanked = vim.fn.getreg('"')
      assert.is_true(yanked:match('bar') ~= nil)
      assert.is_true(yanked:match('baz') ~= nil)
    end)

    it('deletes multiline curly braces content', function()
      set_buffer({ 'foo {', '  bar', '  baz', '}' })
      perform_beam_operation('delete', 'i{', { 2, 2 })
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equals(2, #lines)
      assert.equals('foo {', lines[1])
      assert.equals('}', lines[2])
    end)
  end)

  describe('markdown code block operations', function()
    it('yanks inside markdown code block', function()
      set_buffer({ 'text before', '```lua', 'local x = 1', 'local y = 2', '```', 'text after' })
      perform_beam_operation('yank', 'im', { 3, 0 })
      local yanked = vim.fn.getreg('"')
      assert.is_true(yanked:match('local x = 1') ~= nil)
      assert.is_true(yanked:match('local y = 2') ~= nil)
    end)

    it('yanks around markdown code block', function()
      set_buffer({ 'text before', '```lua', 'local x = 1', 'local y = 2', '```', 'text after' })
      perform_beam_operation('yank', 'am', { 3, 0 })
      local yanked = vim.fn.getreg('"')
      assert.is_true(yanked:match('```lua') ~= nil)
      assert.is_true(yanked:match('local x = 1') ~= nil)
      assert.is_true(yanked:match('```') ~= nil)
    end)

    it('deletes inside markdown code block', function()
      set_buffer({ 'text before', '```lua', 'local x = 1', 'local y = 2', '```', 'text after' })
      perform_beam_operation('delete', 'im', { 3, 0 })
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equals(4, #lines)
      assert.equals('text before', lines[1])
      assert.equals('```lua', lines[2])
      assert.equals('```', lines[3])
      assert.equals('text after', lines[4])
    end)

    it('changes inside markdown code block', function()
      set_buffer({ 'text before', '```lua', 'local x = 1', 'local y = 2', '```', 'text after' })
      perform_beam_operation('change', 'im', { 3, 0 })
      -- Process feedkeys queue
      vim.api.nvim_feedkeys('', 'x', false)
      vim.cmd('stopinsert')
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      -- Change operation leaves an empty line (unlike delete)
      assert.equals(5, #lines)
      assert.equals('text before', lines[1])
      assert.equals('```lua', lines[2])
      assert.equals('', lines[3]) -- Empty line where content was changed
      assert.equals('```', lines[4])
      assert.equals('text after', lines[5])
    end)
  end)
end)
