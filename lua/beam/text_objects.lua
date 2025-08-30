local M = {}

M.custom_objects = {}

function M.register_custom_text_object(key, opts)
  if type(opts) == 'string' then
    return
  end
  
  if type(opts) ~= 'table' then
    error("Custom text object must be a table with 'desc' and 'select' fields")
  end
  
  if not opts.select then
    error("Custom text object must have a 'select' function")
  end
  
  M.custom_objects[key] = opts
  
  vim.keymap.set('o', 'i' .. key, function()
    opts.select(false)
  end, { desc = opts.desc or ('inside ' .. key) })
  
  vim.keymap.set('o', 'a' .. key, function()
    opts.select(true)
  end, { desc = opts.desc or ('around ' .. key) })
  
  vim.keymap.set('x', 'i' .. key, function()
    opts.select(false)
  end, { desc = opts.desc or ('inside ' .. key) })
  
  vim.keymap.set('x', 'a' .. key, function()
    opts.select(true)
  end, { desc = opts.desc or ('around ' .. key) })
end

function M.select_markdown_codeblock(inclusive)
  vim.cmd "call search('```', 'cb')"
  
  if inclusive then
    vim.cmd "normal! Vo"
  else  
    vim.cmd "normal! j0Vo"
  end
  
  vim.cmd "call search('```')"
  
  if not inclusive then
    vim.cmd "normal! k"
  end
end

function M.setup_defaults()
  M.register_custom_text_object('m', {
    desc = 'markdown code block',
    select = M.select_markdown_codeblock
  })
end

return M