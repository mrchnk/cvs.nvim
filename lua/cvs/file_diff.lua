local diff = require('cvs.diff')

local _tab
local _win_left
local _win_right

local function get_file_lines(file)
  local file_str = vim.fn.system('cat ' .. file)
  if vim.v.shell_error > 0 then
    error(file_str)
  end
  return vim.split(file_str, '\n')
end

local function diff_file(file)
  local diff_str = vim.fn.system('cvs diff ' .. file)
  if vim.v.shell_error == 0 then
    error('File not changed')
  end
  return diff.parse(vim.split(diff_str, '\n'))
end

local function unpatch_file(file, diff_obj)
  local file_lines = get_file_lines(file)
  return diff.unpatch(file_lines, diff_obj)
end

local function create_buf(lines, name, rev)
  local full_name = name .. ',' .. rev
  local bufnr = vim.fn.bufnr(full_name)
  if bufnr > 0 then
    return bufnr
  end
  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, full_name)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
  return bufnr
end

local function open_file(file)
  vim.cmd.badd(file)
  --vim.cmd.edit(file)
  --local bufnr = vim.api.nvim_get_current_buf()
  --return bufnr
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
  -- vim.cmd.edit(file)
  local diff_obj, diff_head = diff_file(file)
  local lines_left = unpatch_file(file, diff_obj)
  local buf_left = create_buf(lines_left, file, diff_head.rev1)
  local buf_right = open_file(file)
  open_tab(buf_left, buf_right)
end
