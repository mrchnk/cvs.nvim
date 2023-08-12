local cvs_up = require('cvs.up')

local _win_left
local _win_right

local function open_buffer(name, body)
  local bufnr = vim.fn.bufnr(name)
  if bufnr > 0 then
    return bufnr
  end
  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, name)
  local size = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_buf_set_lines(bufnr, 0, size, true, body)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
  return bufnr
end

local function open_file(file)
  vim.cmd.badd(file)
  return vim.fn.bufnr(file)
end

local function setup_window(win)
  vim.cmd.diffthis()
  vim.api.nvim_win_set_option(win, 'foldmethod', 'diff')
end

local function open_tab(buf_left, buf_right)
  vim.cmd('tab sb' .. buf_right)
  _win_right = vim.api.nvim_get_current_win()
  setup_window(_win_right)
  vim.cmd('vertical sb' .. buf_left)
  _win_left = vim.api.nvim_get_current_win()
  setup_window(_win_left)
end


local function open(entry)
  if entry.body and entry.rev then
    local name = string.format("%s,%s", entry.file, entry.rev)
    return open_buffer(name, entry.body)
  else
    return open_file(entry.file)
  end
end

return function (left, right)
  local buf_left = open(left)
  local buf_right = open(right)
  open_tab(buf_left, buf_right)
end
