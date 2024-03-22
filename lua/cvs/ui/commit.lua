local make_args = require('cvs.utils.make_args')
local cvs = require('cvs.sys')

local function get_screen_size()
  local width = vim.o.columns
  local height = vim.o.lines
  return width, height
end

local function is_empty(lines)
  if #lines == 0 then
    return true
  end
  for _, line in ipairs(lines) do
    if #line > 0 and string.find(line, '%s+') ~= line then
      return false
    end
  end
  return true
end

local function ask_commit_message(msg, cb, opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, msg)
  local swidth, sheight = get_screen_size()
  local width, height = math.min(80, swidth * 0.8), math.min(20, sheight * 0.6)
  local conf = {
    relative = 'editor',
    width = width,
    height = height,
    border = 'single',
    title = 'Commit message',
    style = 'minimal',
    row = (sheight - height)/2,
    col = (swidth - width)/2,
  }
  local win
  local committed = false
  local function complete()
    if committed then
      return
    end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
    local message = vim.tbl_filter(function (line)
      return not vim.startswith(line, '#')
    end, lines)
    if is_empty(message) then
      error('Empty commit message')
    end
    vim.cmd.stopinsert()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, {force=true})
    cb(message)
    committed = true
  end
  vim.api.nvim_buf_set_keymap(buf, 'i', '<C-S>', '', {callback = complete})
  vim.api.nvim_buf_set_keymap(buf, 'n', '<C-S>', '', {callback = complete})
  vim.api.nvim_buf_set_keymap(buf, 'n', '<ESC>', '', {
    callback = function()
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, {force=true})
      if opts.go_back then
        opts.go_back()
      end
    end,
  })
  win = vim.api.nvim_open_win(buf, true, conf)
  vim.cmd.startinsert()
end

local function has_with_status(s_files, statuses)
  for _, s_file in ipairs(s_files) do
    if statuses[s_file[1]] then
      return true
    end
  end
  return false
end

local function with_status(s_files, status)
  local files = {}
  for _, s_file in ipairs(s_files) do
    if status == s_file[1] then
      table.insert(files, s_file[2])
    end
  end
  return files
end


local function format_info(files)
  local msg = {
    '',
    '# Please enter commit message for your changes. Lines started with "#" will',
    '# be ignored in commit message. Press <Ctrl-S> to submit.',
  }
  local function add_with_status(head, statuses)
    if not has_with_status(files, statuses) then
      return
    end
    table.insert(msg, '#')
    table.insert(msg, head)
    for _, line in ipairs(files) do
      local s, file = unpack(line)
      local name = statuses[s]
      if name == true then
        table.insert(msg, string.format('#    %s', file))
      elseif name then
        table.insert(msg, string.format('#    %-10s %s', name .. ':', file))
      end
    end
  end
  add_with_status('# Files to be committed:', {
    R = 'deleted',
    A = 'new file',
    M = 'modified',
  })
  add_with_status('# Files checked out in older revisions:', {
    P = true,
  })
  add_with_status('# Missing files in working tree:', {
    U = true,
  })
  add_with_status('# Untracked files:', {
    ['?'] = true
  })
  return msg
end

local function cvs_commit(files, message)
  local msg_file = vim.fn.tempname()
  vim.fn.writefile(message, msg_file)
  local cmd = string.format('cvs commit -F "%s" %s', msg_file, make_args(files))
  vim.cmd('!' .. cmd)
  vim.fn.delete(msg_file)
end

return function (files, opts)
  local s_files = cvs.status(files)
  local missing_files = with_status(s_files, 'U')
  if #missing_files == 1 then
    error(string.format('File %s is missing', make_args(missing_files)))
  elseif #missing_files > 1 then
    error(string.format('Files %s are missing', make_args(missing_files)))
  elseif not has_with_status(s_files, {R = true, A = true, M = true}) then
    error('No changes to commit')
  end
  local info = format_info(s_files)
  ask_commit_message(info, function (message)
    cvs_commit(files, message)
  end, opts or {})
end

