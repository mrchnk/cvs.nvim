local cvs = require('cvs.sys')
local cmd_id = require('cvs.cmd.id')
local cvs_hl = require('cvs.ui.highlight')
local buf_from_file = require('cvs.utils.buf_from_file')
local buf_from_rev = require('cvs.utils.buf_from_rev')
local get_temp = require('cvs.utils.get_temp')
local Popover = require('cvs.ui.popover')
local Signs = require('cvs.ui.annotate_signs')

local Annotate = {}

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

local function minmax(tbl, fn)
  local min = nil
  local max = nil
  for _, entry in ipairs(tbl) do
    local v = fn(entry)
    if v then
      if min and max then
        min = v < min and v or min
        max = v > max and v or max
      else
        min = v
        max = v
      end
    end
  end
  return min, max
end

local function find_lnum(lines, needle)
  for idx, line in ipairs(lines) do
    if line.rev == needle.rev and line.line == needle.line then
      return idx
    end
  end
end

local function win_get_opts(win, opts)
  local val = {}
  for _, name in ipairs(opts) do
    val[name] = vim.api.nvim_get_option_value(name, { win = win })
  end
  return val
end

local function win_set_opts(win, opts)
  for name, value in pairs(opts) do
    vim.api.nvim_set_option_value(name, value, { win = win })
  end
end


local function setup_window(self)
  local win = self.win
  local annotate_win
  vim.api.nvim_win_call(win, function ()
    vim.cmd('lefta vs')
    annotate_win = vim.api.nvim_get_current_win()
  end)
  self._win_opt = win_get_opts(win, {'cursorbind', 'scrollbind', 'cursorline'})
  win_set_opts(win, {
    cursorbind = true,
    scrollbind = true,
    cursorline = true,
    scrollopt = 'ver,jump',
    wrap = false,
  })
  win_set_opts(annotate_win, {
    cursorbind = true,
    scrollbind = true,
    cursorline = true,
    scrollopt = 'ver,jump',
    wrap = false,
    number = false,
    signcolumn = 'no',
  })
  self._annotate_win = annotate_win
end

local function get_line(self)
  if not self._meta then
    return nil
  end
  local idx = vim.api.nvim_win_get_cursor(self.win)[1]
  return self._meta[idx], idx
end

local function format_commit(commit)
  local author = commit.author
  local date = commit.date
  local message = commit.message
  local lines = {
    string.format('Author: %s', author),
    string.format('Date:   %s', date),
    '',
  }
  for _, line in ipairs(message) do
    table.insert(lines, '    ' .. line)
  end
  return lines
end

local function build_annotate(self)
  local meta = vim.deepcopy(self._annotate)
  local buf = self.buf
  local a = table.concat(vim.tbl_map(function (entry) return entry.line end, meta), '\n')
  local b = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, true), '\n')
  local function replace(idx, len, cnt, val)
    for _ = 1, len do
      table.remove(meta, idx)
    end
    for _ = 1, cnt do
      table.insert(meta, idx, val)
    end
  end
  local shift = 0
  vim.diff(a, b, {on_hunk = function (a_i, a_c, b_i, b_c)
    if a_c > 0 then
      replace(a_i + shift, a_c, b_c, { line = '' })
      shift = shift + b_c - a_c
    else
      replace(a_i + shift + 1, 0, b_c, { line = '' })
      shift = shift + b_c
    end
  end})
  local max_author_width = max_width(meta, 'author')
  local max_rev_width = max_width(meta, 'rev') + 2
  local max_date_width = max_width(meta, 'date')
  local fmt = string.format('%%-%ds %%%ds %%%ds', max_author_width, max_rev_width, max_date_width)
  local lines = vim.tbl_map(function (entry)
    if not entry.author then
      return entry.line
    else
      return string.format(fmt, entry.author, '-r' .. entry.rev, entry.date)
    end
  end, meta)
  return lines, meta, {max_author_width, max_rev_width, max_date_width}
end

local function get_cursor_line(self)
  return 10
end

local function setup_buffer(self)
  local annotate_win = self._annotate_win
  local annotate_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(annotate_win, annotate_buf)
  self._annotate_buf = annotate_buf
end

local function setup_popover(self)
  self._popover = Popover{
    buf = self._annotate_buf,
    win = self._annotate_win,
  }
end

local function update_annotate(self)
  local lines, meta, widths = build_annotate(self)
  local buf = self._annotate_buf
  local win = self._annotate_win
  local width = max_width(lines)
  local min_ts, max_ts = minmax(meta, function (entry) return entry.ts end)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  vim.api.nvim_win_set_width(win, width)
  for idx, entry in ipairs(meta) do
    if entry.author then
      vim.api.nvim_buf_add_highlight(buf, 0, cvs_hl.id.author, idx-1, 0, widths[1])
    end
    if entry.ts then
      local temp = get_temp(entry.ts, min_ts, max_ts)
      entry.temp = temp
      vim.api.nvim_buf_add_highlight(buf, 0, cvs_hl.get_annotate(temp), idx-1, widths[1] + widths[2] + 2, widths[1] + widths[2] + widths[3] + 2)
    end
  end
  self._meta = meta
  self._signs = Signs{
    buf = self.buf,
    annotate = meta,
  }
end

local function update_signs(self)
  local line = get_line(self) or {}
  self._signs:open(line.rev)
end

local function update_popover(self)
  local line = get_line(self)
  if line and line.commit and self._popover_enabled then
    self._popover:open()
    self._popover:move_to(10, get_cursor_line(self))
    self._popover:set_text(format_commit(line.commit))
  else
    self._popover:close()
  end
end

local function syncbind(win)
  vim.api.nvim_win_call(win, function ()
    vim.cmd.syncbind()
  end)
end

local function on_select(self)
  local line, idx = get_line(self)
  if line and line.rev and self.rev ~= line.rev then
    self._signs:close()
    vim.api.nvim_buf_del_user_command(self.buf, cmd_id.annotate)
    local file = self.file
    local rev = line.rev
    local buf = buf_from_rev(file, rev)
    local view = vim.fn.winsaveview()
    self._prev = {
      file = file,
      rev = self.rev,
      buf = self.buf,
      annotate = self._annotate,
      prev = self._prev,
      view = view
    }
    self.buf = buf
    self.rev = rev
    self._annotate = cvs.annotate(file, { rev = rev })
    vim.api.nvim_win_set_buf(self.win, buf)
    vim.api.nvim_buf_create_user_command(self.buf, cmd_id.annotate, function () self:close() end, {})
    update_annotate(self)
    update_signs(self)
    local lnum = find_lnum(self._meta, line)
    if lnum then
      vim.fn.winrestview({
        lnum = lnum,
        topline = view.topline + lnum - idx,
      })
    end
    syncbind(self._annotate_win)
  end
end

local function go_back(self)
  local prev = self._prev
  if prev then
    self._signs:close()
    vim.api.nvim_buf_del_user_command(self.buf, cmd_id.annotate)
    self.file = prev.file
    self.rev = prev.rev
    self.buf = prev.buf
    self._annotate = prev.annotate
    self._prev = prev.prev
    vim.api.nvim_win_set_buf(self.win, self.buf)
    vim.api.nvim_buf_create_user_command(self.buf, cmd_id.annotate, function () self:close() end, {})
    update_annotate(self)
    update_signs(self)
    vim.fn.winrestview(prev.view)
    syncbind(self._annotate_win)
  end
end

local function subscribe(self)
  local annotate_buf = self._annotate_buf
  local _be = vim.api.nvim_create_autocmd('BufEnter', { buffer = annotate_buf, callback = function ()
    self._popover_enabled = true
    update_popover(self)
  end})
  local _bl = vim.api.nvim_create_autocmd('BufLeave', { buffer = annotate_buf, callback = function ()
    self._popover_enabled = false
    update_popover(self)
  end})
  local _cm = vim.api.nvim_create_autocmd('CursorMoved', { buffer = annotate_buf, callback = function ()
    update_signs(self)
    update_popover(self)
  end})
  local cm = vim.api.nvim_create_autocmd('CursorMoved', { callback = function (event)
    if event.buf == self.buf then
      update_signs(self)
    end
  end})
  vim.api.nvim_buf_create_user_command(self.buf, cmd_id.annotate, function () self:close() end, {})
  vim.api.nvim_buf_create_user_command(annotate_buf, cmd_id.annotate, function () self:close() end, {})
  vim.keymap.set('n', '<CR>', function() on_select(self) end, { noremap = true, buffer = annotate_buf })
  vim.keymap.set('n', '<BS>', function() go_back(self) end, { noremap = true, buffer = annotate_buf })
  self._autocmd = {_be, _bl, _cm, cm}
end

local function unsubscribe(self)
  for _, id in ipairs(self._autocmd) do
    vim.api.nvim_del_autocmd(id)
  end
  vim.api.nvim_buf_del_user_command(self._annotate_buf, cmd_id.annotate)
  vim.api.nvim_buf_del_user_command(self.buf, cmd_id.annotate)
end

function Annotate.open(self)
  setup_window(self)
  setup_buffer(self)
  setup_popover(self)
  subscribe(self)
  update_annotate(self)
  update_signs(self)
  syncbind(self.win)
end

function Annotate.close(self)
  unsubscribe(self)
  self._popover:close()
  self._signs:close()
  vim.api.nvim_win_close(self._annotate_win, true)
  vim.api.nvim_buf_delete(self._annotate_buf, { force = true })
  win_set_opts(self.win, self._win_opt)
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
  local file
  if opts.file then
    file = opts.file
  else
    vim.api.nvim_win_call(win, function ()
      file = vim.fn.expand('%')
    end)
  end
  local buf = opts.buf or
    opts.rev and buf_from_rev(file, opts.rev) or
    buf_from_file(file)
  local annotate = cvs.annotate(file, { rev = opts.rev })
  return setmetatable({
    buf = buf,
    win = win,
    file = file,
    rev = opts.rev or 'HEAD',
    _annotate = annotate,
  }, {
    __index = Annotate
  })
end

