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

local function open_file(file)
  vim.cmd.badd(file)
  return vim.fn.bufnr(file)
end

local function setup_window(win)
  vim.api.nvim_win_call(win, function ()
    vim.cmd.diffthis()
  end)
  vim.api.nvim_win_set_option(win, 'foldmethod', 'diff')
  vim.api.nvim_win_set_option(win, 'foldlevel', 0)
end

local function open_tab(buf_left, buf_right)
  vim.cmd('tab sb' .. buf_right)
  local win_right = vim.api.nvim_get_current_win()
  setup_window(win_right)
  vim.cmd('vertical sb' .. buf_left)
  local win_left = vim.api.nvim_get_current_win()
  setup_window(win_left)
end


local function open(entry)
  if entry.body and entry.rev then
    local name = string.format("%s,%s", entry.file, entry.rev)
    return open_buffer(name, entry.body)
  else
    return open_file(entry.file)
  end
end

local function from(file, rev)
  if rev == 'HEAD' then
    return open_file(file)
  elseif rev then
    return open(cvs_up(file, rev))
  else
    return open_buffer('/dev/null', {})
  end
end

local function open_diff(entry)
  local file = entry.file
  local left = from(file, entry.rev1)
  local right = from(file, entry.rev2)
  return left, right
end

return function (left, right)
  local buf_left
  local buf_right
  if not right then
    buf_left, buf_right = open_diff(left)
  else
    buf_left = open(left)
    buf_right = open(right)
  end
  open_tab(buf_left, buf_right)
end

