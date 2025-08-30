local M = {}

-- Store custom text object implementations
M.custom_objects = {}

-- Register a custom text object with its implementation
function M.register_custom_text_object(key, opts)
  if type(opts) == 'string' then
    -- Just a description, no implementation
    return
  end
  
  if type(opts) ~= 'table' then
    error("Custom text object must be a table with 'desc' and 'select' fields")
  end
  
  if not opts.select then
    error("Custom text object must have a 'select' function")
  end
  
  M.custom_objects[key] = opts
  
  -- Register the actual Vim text object mappings
  -- Operator-pending mode (for d, y, c, etc.)
  vim.keymap.set('o', 'i' .. key, function()
    opts.select(false) -- inside
  end, { desc = opts.desc or ('inside ' .. key) })
  
  vim.keymap.set('o', 'a' .. key, function()
    opts.select(true) -- around
  end, { desc = opts.desc or ('around ' .. key) })
  
  -- Visual mode (for selecting)
  vim.keymap.set('x', 'i' .. key, function()
    opts.select(false) -- inside
  end, { desc = opts.desc or ('inside ' .. key) })
  
  vim.keymap.set('x', 'a' .. key, function()
    opts.select(true) -- around
  end, { desc = opts.desc or ('around ' .. key) })
end

-- Built-in markdown code block text object
function M.select_markdown_codeblock(inclusive)
  -- Search backward for opening ```
  vim.cmd "call search('```', 'cb')"
  
  if inclusive then
    -- am - around (include backticks)
    vim.cmd "normal! Vo"
  else  
    -- im - inside (exclude backticks)
    vim.cmd "normal! j0Vo"
  end
  
  -- Search forward for closing ```
  vim.cmd "call search('```')"
  
  if not inclusive then
    -- For inside, go up one line to exclude the closing ```
    vim.cmd "normal! k"
  end
end

-- Register default custom text objects
function M.setup_defaults()
  -- Register markdown code block text object
  M.register_custom_text_object('m', {
    desc = 'markdown code block',
    select = M.select_markdown_codeblock
  })
end

return M