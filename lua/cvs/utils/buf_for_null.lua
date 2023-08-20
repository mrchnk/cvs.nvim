local name = '/dev/null'
local body = {}

return function ()
  local buf = vim.fn.bufnr(name)
  if buf > 0 then
    return buf
  end
  buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, body)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  return buf
end

