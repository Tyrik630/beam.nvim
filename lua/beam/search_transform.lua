local M = {}

-- Text object delimiter patterns for constraining search
M.textobj_constraints = {
  -- Quote-based text objects
  ['i"'] = {
    delim_open = '"',
    delim_close = '"',
    wrap_pattern = function(search)
      return [[\v"[^"]*\zs]] .. search .. [[\ze[^"]*"]]
    end,
  },
  ["i'"] = {
    delim_open = "'",
    delim_close = "'",
    wrap_pattern = function(search)
      return [[\v'[^']*\zs]] .. search .. [[\ze[^']*']]
    end,
  },
  ['i`'] = {
    delim_open = '`',
    delim_close = '`',
    wrap_pattern = function(search)
      return [[\v`[^`]*\zs]] .. search .. [[\ze[^`]*`]]
    end,
  },
  ['a"'] = {
    delim_open = '"',
    delim_close = '"',
    wrap_pattern = function(search)
      return [[\v"\zs[^"]*]] .. search .. [[[^"]*\ze"]]
    end,
  },
  ["a'"] = {
    delim_open = "'",
    delim_close = "'",
    wrap_pattern = function(search)
      return [[\v'\zs[^']*]] .. search .. [[[^']*\ze']]
    end,
  },
  ['a`'] = {
    delim_open = '`',
    delim_close = '`',
    wrap_pattern = function(search)
      return [[\v`\zs[^`]*]] .. search .. [[[^`]*\ze`]]
    end,
  },

  -- Bracket-based text objects
  ['i{'] = {
    delim_open = '{',
    delim_close = '}',
    wrap_pattern = function(search)
      return [[\v\{\_[^}]*\zs]] .. search .. [[\ze\_[^}]*\}]]
    end,
  },
  ['i}'] = {
    delim_open = '{',
    delim_close = '}',
    wrap_pattern = function(search)
      return [[\v\{\_[^}]*\zs]] .. search .. [[\ze\_[^}]*\}]]
    end,
  },
  ['a{'] = {
    delim_open = '{',
    delim_close = '}',
    wrap_pattern = function(search)
      return [[\v\{\zs\_[^}]*]] .. search .. [[\_[^}]*\ze\}]]
    end,
  },
  ['a}'] = {
    delim_open = '{',
    delim_close = '}',
    wrap_pattern = function(search)
      return [[\v\{\zs\_[^}]*]] .. search .. [[\_[^}]*\ze\}]]
    end,
  },

  ['i('] = {
    delim_open = '(',
    delim_close = ')',
    wrap_pattern = function(search)
      return [[\v\([^)]*\zs]] .. search .. [[\ze[^)]*\)]]
    end,
  },
  ['i)'] = {
    delim_open = '(',
    delim_close = ')',
    wrap_pattern = function(search)
      return [[\v\([^)]*\zs]] .. search .. [[\ze[^)]*\)]]
    end,
  },
  ['a('] = {
    delim_open = '(',
    delim_close = ')',
    wrap_pattern = function(search)
      return [[\v\(\zs[^)]*]] .. search .. [[[^)]*\ze\)]]
    end,
  },
  ['a)'] = {
    delim_open = '(',
    delim_close = ')',
    wrap_pattern = function(search)
      return [[\v\(\zs[^)]*]] .. search .. [[[^)]*\ze\)]]
    end,
  },

  ['i['] = {
    delim_open = '[',
    delim_close = ']',
    wrap_pattern = function(search)
      return '\\v\\[[^\\]]*\\zs' .. search .. '\\ze[^\\]]*\\]'
    end,
  },
  ['i]'] = {
    delim_open = '[',
    delim_close = ']',
    wrap_pattern = function(search)
      return '\\v\\[[^\\]]*\\zs' .. search .. '\\ze[^\\]]*\\]'
    end,
  },
  ['a['] = {
    delim_open = '[',
    delim_close = ']',
    wrap_pattern = function(search)
      return '\\v\\[\\zs[^\\]]*' .. search .. '[^\\]]*\\ze\\]'
    end,
  },
  ['a]'] = {
    delim_open = '[',
    delim_close = ']',
    wrap_pattern = function(search)
      return '\\v\\[\\zs[^\\]]*' .. search .. '[^\\]]*\\ze\\]'
    end,
  },

  ['i<'] = {
    delim_open = '<',
    delim_close = '>',
    wrap_pattern = function(search)
      return [[\v\<[^>]*\zs]] .. search .. [[\ze[^>]*\>]]
    end,
  },
  ['i>'] = {
    delim_open = '<',
    delim_close = '>',
    wrap_pattern = function(search)
      return [[\v\<[^>]*\zs]] .. search .. [[\ze[^>]*\>]]
    end,
  },
  ['a<'] = {
    delim_open = '<',
    delim_close = '>',
    wrap_pattern = function(search)
      return [[\v\<\zs[^>]*]] .. search .. [[[^>]*\ze\>]]
    end,
  },
  ['a>'] = {
    delim_open = '<',
    delim_close = '>',
    wrap_pattern = function(search)
      return [[\v\<\zs[^>]*]] .. search .. [[[^>]*\ze\>]]
    end,
  },

  -- Alternative bracket syntax (b = parentheses)
  ['ib'] = {
    delim_open = '(',
    delim_close = ')',
    wrap_pattern = function(search)
      -- Same as i(
      return [[\v\([^)]*\zs]] .. search .. [[\ze[^)]*\)]]
    end,
  },
  ['ab'] = {
    delim_open = '(',
    delim_close = ')',
    wrap_pattern = function(search)
      -- Same as a(
      return [[\v\(\zs[^)]*]] .. search .. [[[^)]*\ze\)]]
    end,
  },

  -- Alternative brace syntax (B = braces/curly brackets)
  ['iB'] = {
    delim_open = '{',
    delim_close = '}',
    wrap_pattern = function(search)
      return [[\v\{\_[^}]*\zs]] .. search .. [[\ze\_[^}]*\}]]
    end,
  },
  ['aB'] = {
    delim_open = '{',
    delim_close = '}',
    wrap_pattern = function(search)
      return [[\v\{\zs\_[^}]*]] .. search .. [[\_[^}]*\ze\}]]
    end,
  },

  -- Alternative quote syntax (q = quotes, defaults to double quotes)
  ['iq'] = {
    delim_open = '"',
    delim_close = '"',
    wrap_pattern = function(search)
      -- Same as i"
      return [[\v"[^"]*\zs]] .. search .. [[\ze[^"]*"]]
    end,
  },
  ['aq'] = {
    delim_open = '"',
    delim_close = '"',
    wrap_pattern = function(search)
      -- Same as a"
      return [[\v"\zs[^"]*]] .. search .. [[[^"]*\ze"]]
    end,
  },

  -- HTML/XML tags (for 't' text object)
  ['it'] = {
    delim_open = '<tag>',
    delim_close = '</tag>',
    wrap_pattern = function(search)
      -- Match inside any HTML/XML tag pair
      return [[\v\<\w+[^>]*\>\zs]] .. search .. [[\ze\</\w+\>]]
    end,
  },
  ['at'] = {
    delim_open = '<tag>',
    delim_close = '</tag>',
    wrap_pattern = function(search)
      -- Match around HTML/XML tags (including tags)
      return [[\v\<\w+[^>]*\>]] .. search .. [[\</\w+\>]]
    end,
  },

  -- Function arguments (for 'a' text object - commonly used with treesitter)
  ['ia'] = {
    delim_open = '(',
    delim_close = ')',
    wrap_pattern = function(search)
      -- Similar to i( but more semantic
      return [[\v\([^)]*\zs]] .. search .. [[\ze[^)]*\)]]
    end,
  },

  -- Block comments (for various languages)
  ['iC'] = {
    delim_open = '/*',
    delim_close = '*/',
    wrap_pattern = function(search)
      -- Match inside C-style block comments
      return [[\v/\*\zs%(.*\n)*]] .. search .. [[%(.*\n)*\ze\*/]]
    end,
  },
  ['aC'] = {
    delim_open = '/*',
    delim_close = '*/',
    wrap_pattern = function(search)
      -- Match around C-style block comments
      return [[\v/\*%(.*\n)*]] .. search .. [[%(.*\n)*\*/]]
    end,
  },
}

-- Check if a text object has delimiter constraints
function M.has_constraints(textobj)
  return M.textobj_constraints[textobj] ~= nil
end

-- Transform a search pattern based on the text object constraints
function M.transform_search_pattern(pattern, textobj, config)
  -- Check if smart highlighting is enabled
  if not config or not config.smart_highlighting then
    return pattern
  end

  -- Get constraint for this text object
  local constraint = M.textobj_constraints[textobj]
  if not constraint or not constraint.wrap_pattern then
    return pattern
  end

  -- Apply the transformation
  local transformed = constraint.wrap_pattern(pattern)
  return transformed
end

-- Get delimiter info for a text object
function M.get_delimiter_info(textobj)
  local constraint = M.textobj_constraints[textobj]
  if not constraint then
    return nil
  end

  return {
    open = constraint.delim_open,
    close = constraint.delim_close,
  }
end

-- Allow users to register custom delimiter patterns
function M.register_custom_constraint(textobj, constraint)
  if type(constraint) == 'table' and constraint.wrap_pattern then
    M.textobj_constraints[textobj] = constraint
  end
end

return M
