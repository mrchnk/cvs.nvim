local buf_from_file = require('cvs.utils.buf_from_file')
local buf_from_rev = require('cvs.utils.buf_from_rev')

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

local function setup_window(win)
  vim.api.nvim_win_call(win, function ()
    vim.cmd.diffthis()
  end)
  vim.api.nvim_win_set_option(win, 'foldmethod', 'diff')
  vim.api.nvim_win_set_option(win, 'foldlevel', 1)
end

local function open_tab(buf_left, buf_right)
  vim.cmd('tab sb' .. buf_right)
  local win_right = vim.api.nvim_get_current_win()
  setup_window(win_right)
  vim.cmd('vertical sb' .. buf_left)
  local win_left = vim.api.nvim_get_current_win()
  setup_window(win_left)
end

local function buf_from_entry(entry)
  local file = entry.file
  local rev = entry.rev
  local body = entry.body
  if rev == 'HEAD' then
    return buf_from_file(file)
  elseif rev then
    return buf_from_rev(file, rev, body)
  else
    return open_buffer('/dev/null', {})
  end
end

local function buf_from_diff(entry)
  local file = entry.file
  local left = buf_from_entry{ file = file, rev = entry.rev1 }
  local right = buf_from_entry{ file = file, rev = entry.rev2 }
  return left, right
end

return function (left, right)
  local buf_left
  local buf_right
  if not right then
    buf_left, buf_right = buf_from_diff(left)
  else
    buf_left = buf_from_entry(left)
    buf_right = buf_from_entry(right)
  end
  open_tab(buf_left, buf_right)
end

