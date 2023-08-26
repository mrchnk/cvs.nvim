local cvs_up = require('cvs.sys.up')

local function open_buffer(name, body, filetype)
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, body)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  if filetype then
    vim.api.nvim_buf_set_option(buf, 'filetype', filetype)
  end
  return buf
end

local function get_name(file, rev)
  local name_wo_ext = vim.fn.fnamemodify(file, ':r')
  local ext = vim.fn.fnamemodify(file, ':e')
  if #ext > 0 then
    return string.format('%s.r%s.%s', name_wo_ext, rev, ext)
  else
    return string.format('%s.r%s', file, rev)
  end
end

return function (file, rev, body)
  local name = string.format('%s -r%s', file, rev)
  local buf = vim.fn.bufnr(name)
  if buf > 0 then
    return buf
  end
  if not body then
    body = cvs_up(file, rev).body
  end
  local filetype = vim.filetype.match{ filename = file }
  return open_buffer(name, body, filetype)
end
