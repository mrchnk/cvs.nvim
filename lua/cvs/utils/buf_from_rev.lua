local cvs_up = require('cvs.up')

local function open_buffer(name, body, filetype)
  local bufnr = vim.fn.bufnr(name)
  if bufnr > 0 then
    return bufnr
  end
  bufnr = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(bufnr, name)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, body)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', filetype)
  return bufnr
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

return function (file, rev)
  local entry = cvs_up(file, rev)
  local name = string.format('%s~r%s', file, rev)
  local filetype = vim.filetype.match{ filename = file }
  return open_buffer(name, entry.body, filetype)
end
