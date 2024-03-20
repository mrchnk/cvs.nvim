local cvs = require('cvs.sys')

local function open_buffer(name, body, filetype, file, rev)
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, body)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  if filetype then
    vim.api.nvim_buf_set_option(buf, 'filetype', filetype)
  end
  return buf
end

return function (file, rev, body)
  local name = string.format('%s -r%s', file, rev)
  local buf = vim.fn.bufnr(name)
  if buf > 0 then
    return buf
  end
  if not body then
    body = cvs.up(file, rev).body
  end
  local filetype = vim.filetype.match{ filename = file }
  buf = open_buffer(name, body, filetype)
  vim.api.nvim_buf_set_var(buf, 'cvs_file', file)
  vim.api.nvim_buf_set_var(buf, 'cvs_rev', rev)
  return buf
end
