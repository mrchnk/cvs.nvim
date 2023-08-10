local cvs_up = require('cvs.up')

local _win_left
local _win_right

local function create_buf(lines, name, rev)
  local full_name = name .. ',' .. rev
  local bufnr = vim.fn.bufnr(full_name)
  if bufnr > 0 then
    return bufnr
  end
  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, full_name)
  local size = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_buf_set_lines(bufnr, 0, size, true, lines)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
  return bufnr
end

local function open_file(file)
  vim.cmd.badd(file)
  return vim.fn.bufnr(file)
end

local function open_tab(buf_left, buf_right)
  vim.cmd('tab sb' .. buf_right)
  _win_right = vim.api.nvim_get_current_win()
  vim.cmd.diffthis()
  vim.api.nvim_win_set_option(_win_right, 'foldmethod', 'diff')
  vim.cmd('vertical sb' .. buf_left)
  _win_left = vim.api.nvim_get_current_win()
  vim.cmd.diffthis()
  vim.api.nvim_win_set_option(_win_left, 'foldmethod', 'diff')
end

return function (file, opts)
  local cvs_files = cvs_up(file)
  local buf_left
  if #cvs_files > 0 then
    local cvs_file = cvs_files[1]
    buf_left = create_buf(cvs_file.body, file, cvs_file.rev)
  else
    buf_left = create_buf({}, file, 'UNVERSIONED')
  end
  local buf_right = open_file(file)
  open_tab(buf_left, buf_right)
end
