local cvs_annotate = require('cvs.annotate')
local cvs_log = require('cvs.log')
local buf_from_file = require('cvs.utils.buf_from_file')

local UiAnnotate = {}

local function max_width(result, key)
  local max = 0
  for _, entry in ipairs(result) do
    local line = key and entry[key] or entry
    if #line > max then
      max = #line
    end
  end
  return max
end

local function get_opt(win, opts)
  local val = {}
  for _, name in ipairs(opts) do
    val[name] = vim.api.nvim_get_option_value(name, { win = win })
  end
  return val
end

local function set_opt(win, opts)
  for name, value in pairs(opts) do
    vim.api.nvim_set_option_value(name, value, { win = win })
  end
end

local function combine(annotate, log)
  local function find_commit(rev)
    for _, entry in ipairs(log) do
      for _, commit in ipairs(entry.commits) do
        if commit.rev == rev then
          return commit
        end
      end
    end
  end
  return vim.tbl_map(function (entry)
    local commit = find_commit(entry.rev)
    return {
      rev = entry.rev,
      author = commit and commit.author or entry.author,
      date = entry.date,
      line = entry.line,
      commit = commit,
    }
  end, annotate)
end

local function setup_window(self)
  local win = self.win
  local annotate_win
  vim.api.nvim_win_call(win, function ()
    vim.cmd('lefta vs')
    annotate_win = vim.api.nvim_get_current_win()
  end)
  self._win_opt = get_opt(win, {'cursorbind', 'scrollbind', 'cursorline'})
  set_opt(win, {
    cursorbind = true,
    scrollbind = true,
    cursorline = true,
  })
  set_opt(annotate_win, {
    cursorbind = true,
    scrollbind = true,
    cursorline = true,
    wrap = false,
    number = false,
  })
  self._annotate_win = annotate_win
end

local function open_popover(self)
end

local function close_popover(self)
end

local function update_popover(self)
end

local function setup_signs(self)
  vim.cmd.highlight('CVSAnnotateRev guifg=#00FF00')
  vim.fn.sign_define('CVSAnnotateRev', {
    text = '┃',
    texthl = 'CVSAnnotateRev',
  })
end

local function update_signs(self)
  vim.fn.sign_unplace('CVSAnnotateRev', {buffer = self.buf})
  local meta = self._meta
  if not meta then
    return
  end
  local idx = vim.api.nvim_win_get_cursor(self.win)[1]
  local rev = meta[idx].rev
  if rev then
    for i, entry in ipairs(meta) do
      if entry.rev == rev then
        vim.fn.sign_place(0, 'CVSAnnotateRev', 'CVSAnnotateRev', self.buf, {lnum = i})
      end
    end
  end
end

local function setup_buffer(self)
  local annotate_win = self._annotate_win
  local annotate_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(annotate_win, annotate_buf)
  self._annotate_buf = annotate_buf
end


local function build_annotate(self)
  local annotate = self._annotate
  local result = {unpack(annotate)}
  local buf = self.buf
  local a = table.concat(vim.tbl_map(function (entry) return entry.line end, annotate), '\n')
  local b = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, true), '\n')
  local function replace(idx, len, cnt, val)
    for _ = 1, len do
      table.remove(result, idx)
    end
    for _ = 1, cnt do
      table.insert(result, idx, val)
    end
  end
  local shift = 0
  vim.diff(a, b, {on_hunk = function (a_i, a_c, b_i, b_c)
    if a_c > 0 then
      replace(a_i + shift, a_c, b_c, { line = 'CHANGED' })
      shift = shift + b_c - a_c
    else
      replace(a_i + shift + 1, 0, b_c, { line = 'INSERTED' })
      shift = shift + b_c
    end
  end})
  local max_author_width = max_width(result, 'author')
  local max_rev_width = max_width(result, 'rev') + 2
  local max_date_width = max_width(result, 'date')
  local fmt = string.format('%%-%ds %%%ds %%%ds', max_author_width, max_rev_width, max_date_width)
  local lines = vim.tbl_map(function (entry)
    if not entry.author then
      return entry.line
    else
      return string.format(fmt, entry.author, '-r' .. entry.rev, entry.date)
    end
  end, result)
  return lines, result
end

local function update_annotate(self)
  local lines, meta = build_annotate(self)
  local buf = self._annotate_buf
  local win = self._annotate_win
  local width = max_width(lines) + 2
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  vim.api.nvim_win_set_width(win, width)
  self._meta = meta
end

local function subscribe(self)
  local annotate_buf = self._annotate_buf
  local buf = self.buf
  local _be = vim.api.nvim_create_autocmd('BufEnter', { buffer = annotate_buf, callback = function ()
    open_popover(self)
  end})
  local _bl = vim.api.nvim_create_autocmd('BufLeave', { buffer = annotate_buf, callback = function ()
    close_popover(self)
  end})
  local _cm = vim.api.nvim_create_autocmd('CursorMoved', { buffer = annotate_buf, callback = function ()
    update_signs(self)
    update_popover(self)
  end})
  local cm = vim.api.nvim_create_autocmd('CursorMoved', { buffer = buf, callback = function ()
    update_signs(self)
  end})
  vim.api.nvim_buf_create_user_command(buf, 'CVSAnnotate', function () self:close() end, {})
  vim.api.nvim_buf_create_user_command(annotate_buf, 'CVSAnnotate', function () self:close() end, {})
  self._autocmd = {_be, _bl, _cm, cm}
end

local function unsubscribe(self)
  for _, id in ipairs(self._autocmd) do
    vim.api.nvim_del_autocmd(id)
  end
  vim.api.nvim_buf_del_user_command(self._annotate_buf, 'CVSAnnotate')
  vim.api.nvim_buf_del_user_command(self.buf, 'CVSAnnotate')
end

function UiAnnotate.open(self)
  setup_signs(self)
  setup_window(self)
  setup_buffer(self)
  subscribe(self)
  update_annotate(self)
  update_signs(self)
end

function UiAnnotate.close(self)
  unsubscribe(self)
  vim.api.nvim_win_close(self._annotate_win, true)
  vim.api.nvim_buf_delete(self._annotate_buf, { force = true })
  vim.fn.sign_unplace('CVSAnnotateRev', {buffer = self.buf})
  set_opt(self.win, self._win_opt)
end

--- Open annotate ui for single file
--- @param opts table annotate ui options
return function (opts)
  local win
  if opts.win and opts.win ~= 0 then
    win = opts.win
  else
    win = vim.api.nvim_get_current_win()
  end
  local buf
  local file
  if opts.file then
    file = opts.file
    buf = buf_from_file(file)
  else
    vim.api.nvim_win_call(win, function ()
      file = vim.fn.expand('%')
    end)
    buf = vim.api.nvim_win_get_buf(win)
  end
  local annotate = cvs_annotate(file, {})
  local log = cvs_log({file}, {})
  setmetatable({
    buf = buf,
    win = win,
    file = file,
    _annotate = combine(annotate, log),
  }, {
    __index = UiAnnotate
  }):open()
end
