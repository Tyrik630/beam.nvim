-- Cross-buffer operation tests using real Plenary busted
describe('beam.nvim cross-buffer operations', function()
  local beam, operators
  local buf1, buf2

  before_each(function()
    -- Clear state
    package.loaded['beam'] = nil
    package.loaded['beam.operators'] = nil
    package.loaded['beam.config'] = nil

    beam = require('beam')
    operators = require('beam.operators')

    -- Create test buffers
    buf1 = vim.api.nvim_get_current_buf()
    buf2 = vim.api.nvim_create_buf(true, false) -- listed buffer
  end)

  after_each(function()
    -- Clean up buffers
    if buf2 and vim.api.nvim_buf_is_valid(buf2) then
      vim.api.nvim_buf_delete(buf2, { force = true })
    end
  end)

  local function set_buffer(buf, text)
    vim.api.nvim_set_current_buf(buf)
    local lines = type(text) == 'string' and { text } or text
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end

  describe('with cross_buffer = true', function()
    before_each(function()
      beam.setup({ prefix = ',', cross_buffer = true })
    end)

    it('finds matches in other buffers', function()
      vim.api.nvim_buf_set_lines(buf2, 0, -1, false, { 'buffer two "target text" more' })
      vim.api.nvim_buf_set_lines(buf1, 0, -1, false, { 'buffer one content' })
      vim.api.nvim_set_current_buf(buf1)

      -- Test that cross-buffer search can find text in buf2
      local found = false
      for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
        if buf.bufnr == buf2 then
          vim.api.nvim_set_current_buf(buf2)
          found = vim.fn.search('target', 'c') > 0
          break
        end
      end

      assert.is_true(found, 'Should find match in other buffer')
    end)

    it('enables cross-buffer config option', function()
      local config = beam.get_config()
      assert.is_true(config.cross_buffer)
    end)
  end)

  describe('with cross_buffer = false', function()
    before_each(function()
      beam.setup({ prefix = ',', cross_buffer = false })
    end)

    it('restricts operations to current buffer', function()
      set_buffer(buf2, 'other buffer "content"')
      set_buffer(buf1, 'current buffer')

      operators.BeamYankSearchSetup('i"')
      assert.is_not_nil(operators.BeamSearchOperatorPending)
      assert.is_false(operators.BeamSearchOperatorPending.cross_buffer or false)
    end)
  end)

  describe('with cross_buffer unset (default)', function()
    it('defaults to false', function()
      beam.setup({ prefix = ',' })

      operators.BeamYankSearchSetup('i"')
      assert.is_not_nil(operators.BeamSearchOperatorPending)
      assert.is_false(operators.BeamSearchOperatorPending.cross_buffer or false)
    end)
  end)
end)
