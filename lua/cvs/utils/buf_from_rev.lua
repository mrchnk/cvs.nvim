local cvs_up = require('cvs.up')

local function open_buffer(name, body)
  local bufnr = vim.fn.bufnr(name)
  if bufnr > 0 then
    return bufnr
  end
  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, name)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, body)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
  return bufnr
end

return function (file, rev)
  local entry = cvs_up(file, rev)
  local name = string.format("%s,%s", file, rev)
  return open_buffer(name, entry.body)
end
