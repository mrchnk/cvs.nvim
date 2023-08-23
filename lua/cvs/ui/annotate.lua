local cvs_annotate = require('cvs.annotate')
local cvs_log = require('cvs.log')
local cvs_hl = require('cvs.ui.highlight')
local buf_from_file = require('cvs.utils.buf_from_file')
local popover = require('cvs.ui.popover')

local annotate_sign_id = 'CVSAnnotateRev'
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

local function get_temp(x, a, b)
  return (x - a) / (b - a)
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
      ts = commit and commit.ts or nil,
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
  self._win_opt = win_get_opts(win, {'cursorbind', 'scrollbind', 'cursorline'})
  win_set_opts(win, {
    cursorbind = true,
    scrollbind = true,
    cursorline = true,
  })
  win_set_opts(annotate_win, {
    cursorbind = true,
    scrollbind = true,
    cursorline = true,
    wrap = false,
    number = false,
  })
  self._annotate_win = annotate_win
end

local function get_line(self)
  if not self._meta then
    return nil
  end
  local idx = vim.api.nvim_win_get_cursor(self.win)[1]
  return self._meta[idx]
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

local function get_cursor_line(self)
  return 10
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

local function update_signs(self)
  local line = get_line(self) or {}
  if self._signs_rev ~= line.rev then
    self._signs_rev = line.rev
    vim.fn.sign_unplace(annotate_sign_id, {buffer = self.buf})
    if line.rev then
      local t = line.ts and get_temp(line.ts, self._min_ts, self._max_ts) or 0
      vim.fn.sign_define('CVSAnnotateRev', {
        text = '┃',
        texthl = cvs_hl.get_annotate_fg(t),
      })
      vim.fn.sign_placelist(self._signs[line.rev])
    end
  end
end

local function setup_buffer(self)
  local annotate_win = self._annotate_win
  local annotate_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(annotate_win, annotate_buf)
  self._annotate_buf = annotate_buf
end

local function setup_popover(self)
  self._popover = popover{
    buf = self._annotate_buf,
    win = self._annotate_win,
  }
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

local function build_signs(self, meta)
  local buf = self.buf
  local signs = vim.defaulttable()
  for idx, entry in ipairs(meta) do
    if entry.rev then
      table.insert(signs[entry.rev], {
        buffer = buf,
        name = annotate_sign_id,
        group = annotate_sign_id,
        lnum = idx,
      })
    end
  end
  return signs
end

local function update_annotate(self)
  local lines, meta, widths = build_annotate(self)
  local buf = self._annotate_buf
  local win = self._annotate_win
  local width = max_width(lines) + 2
  local min_ts, max_ts = minmax(meta, function (entry) return entry.ts end)
  self._min_ts = min_ts
  self._max_ts = max_ts
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  vim.api.nvim_win_set_width(win, width)
  for idx, entry in ipairs(meta) do
    if entry.author then
      vim.api.nvim_buf_add_highlight(buf, 0, cvs_hl.id.author, idx-1, 0, widths[1])
    end
    if entry.ts then
      local t = (entry.ts - min_ts) / (max_ts - min_ts)
      vim.api.nvim_buf_add_highlight(buf, 0, cvs_hl.get_annotate(t), idx-1, widths[1] + widths[2] + 2, widths[1] + widths[2] + widths[3] + 2)
    end
  end
  self._meta = meta
  self._signs = build_signs(self, meta)
end

local function subscribe(self)
  local annotate_buf = self._annotate_buf
  local buf = self.buf
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
  setup_window(self)
  setup_buffer(self)
  setup_popover(self)
  subscribe(self)
  update_annotate(self)
  update_signs(self)
end

function UiAnnotate.close(self)
  unsubscribe(self)
  self._popover:close()
  vim.api.nvim_win_close(self._annotate_win, true)
  vim.api.nvim_buf_delete(self._annotate_buf, { force = true })
  vim.fn.sign_unplace('CVSAnnotateRev', {buffer = self.buf})
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
