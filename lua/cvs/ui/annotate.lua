local cvs = require('cvs.sys')
local cmd_id = require('cvs.cmd.id')
local cvs_hl = require('cvs.ui.highlight')
local buf_from_file = require('cvs.utils.buf_from_file')
local buf_from_rev = require('cvs.utils.buf_from_rev')
local get_temp = require('cvs.utils.get_temp')
local format_commit = require('cvs.utils.format_commit')
local Popover = require('cvs.ui.popover')
local Signs = require('cvs.ui.annotate_signs')
local make_commands = require('cvs.ui.annotate_commands')

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

local function find_lnum(annotate, needle)
  for lnum, entry in ipairs(annotate) do
    if entry.rev == needle.rev and entry.line == needle.line then
      return lnum
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
  vim.api.nvim_win_call(win, function()
    vim.cmd('lefta vs')
    annotate_win = vim.api.nvim_get_current_win()
  end)
  self._win_opt = win_get_opts(win, { 'cursorbind', 'scrollbind', 'cursorline', 'scrollopt', 'wrap' })
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

function Annotate.get_cur_entry(self)
  local lnum = vim.api.nvim_win_get_cursor(self.win)[1]
  local entry = self._meta and self._meta[lnum] or {}
  return entry, lnum
end

local function build_annotate(self)
  local meta = vim.deepcopy(self._annotate)
  local buf = self.buf
  local a = table.concat(vim.tbl_map(function(entry) return entry.line end, meta), '\n')
  local b = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, true), '\n')
  local function replace(lnum, len, cnt, val)
    for _ = 1, len do
      table.remove(meta, lnum)
    end
    for _ = 1, cnt do
      table.insert(meta, lnum, val)
    end
  end
  local shift = 0
  vim.diff(a, b, {
    on_hunk = function(a_i, a_c, b_i, b_c)
      if a_c > 0 then
        replace(a_i + shift, a_c, b_c, { line = '' })
        shift = shift + b_c - a_c
      else
        replace(a_i + shift + 1, 0, b_c, { line = '' })
        shift = shift + b_c
      end
    end
  })
  return meta
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
  self._popover = Popover {
    win = self._annotate_win,
  }
end

local function update_annotate(self)
  local buf = self._annotate_buf
  local win = self._annotate_win
  local meta = build_annotate(self)
  local max_author_width = max_width(meta, 'author')
  local max_rev_width = max_width(meta, 'rev') + 2
  local max_date_width = max_width(meta, 'date')
  local fmt = string.format('%%-%ds %%%ds %%%ds', max_author_width, max_rev_width, max_date_width)
  local lines = vim.tbl_map(function(entry)
    if not entry.author then
      return entry.line
    else
      return string.format(fmt, entry.author, '-r' .. entry.rev, entry.date)
    end
  end, meta)
  local width = max_width(lines)
  local min_ts, max_ts = minmax(meta, function(entry) return entry.ts end)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  vim.api.nvim_win_set_width(win, width)
  local author_range = {
    0,
    max_author_width,
  }
  local date_range = {
    max_author_width + max_rev_width + 2,
    max_author_width + max_rev_width + max_date_width + 2,
  }
  for lnum, entry in ipairs(meta) do
    if entry.author then
      local temp = get_temp(entry.ts, min_ts, max_ts)
      local hl = cvs_hl.get_annotate(temp)
      entry.temp = temp
      vim.api.nvim_buf_add_highlight(buf, 0, cvs_hl.id.author, lnum - 1, unpack(author_range))
      vim.api.nvim_buf_add_highlight(buf, 0, hl, lnum - 1, unpack(date_range))
    end
  end
  self._meta = meta
  self._signs = Signs {
    buf = self.buf,
    annotate = meta,
  }
end

local function update_signs(self)
  local entry = self:get_cur_entry()
  self._signs:open(entry.rev)
end

local function update_popover(self)
  local entry = self:get_cur_entry()
  if entry and entry.commit and self._popover_enabled then
    self._popover:open()
    self._popover:move_to(10, get_cursor_line(self))
    self._popover:set_text(format_commit(entry.commit))
  else
    self._popover:close()
  end
end

local function syncbind(win)
  vim.api.nvim_win_call(win, function()
    vim.cmd.syncbind()
  end)
end

local function subscribe(self)
  local autocmd = {}
  local cmd = {}
  local function listen(name, buffer, callback)
    local id = vim.api.nvim_create_autocmd(name, {
      buffer = buffer,
      callback = callback,
    })
    table.insert(autocmd, id)
  end
  local function command(name, buffer, callback)
    vim.api.nvim_buf_create_user_command(buffer, name, callback, {})
    table.insert(cmd, {name, buffer})
  end
  listen('BufEnter', self._annotate_buf, function ()
    self._popover_enabled = true
    update_popover(self)
  end)
  listen('BufLeave', self._annotate_buf, function ()
    self._popover_enabled = false
    update_popover(self)
  end)
  listen('CursorMoved', self._annotate_buf, function ()
    update_signs(self)
    update_popover(self)
  end)
  listen('CursorMoved', self.buf, function ()
      update_signs(self)
  end)
  for name, callback in make_commands(self) do
    for _, buf in ipairs{self._annotate_buf, self.buf} do
      command(name, buf, callback)
    end
  end
  self._autocmd = autocmd
  self._cmd = cmd
end

local function unsubscribe(self)
  for _, id in ipairs(self._autocmd) do
    vim.api.nvim_del_autocmd(id)
  end
  for _, it in ipairs(self._cmd) do
    local name, buffer = unpack(it)
    vim.api.nvim_buf_del_user_command(buffer, name)
  end
end

local function on_select(self)
  local entry, lnum = self:get_cur_entry()
  if entry and entry.rev and self.rev ~= entry.rev then
    self._signs:close()
    unsubscribe(self)
    local file = self.file
    local rev = entry.rev
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
    subscribe(self)
    update_annotate(self)
    update_signs(self)
    local new_lnum = find_lnum(self._meta, entry)
    if new_lnum then
      print(lnum)
      vim.fn.winrestview({
        lnum = new_lnum,
        topline = view.topline + new_lnum - lnum,
      })
    end
    syncbind(self._annotate_win)
  end
end

local function go_back(self)
  local prev = self._prev
  if prev then
    self._signs:close()
    unsubscribe(self)
    self.file = prev.file
    self.rev = prev.rev
    self.buf = prev.buf
    self._annotate = prev.annotate
    self._prev = prev.prev
    vim.api.nvim_win_set_buf(self.win, self.buf)
    subscribe(self)
    update_annotate(self)
    update_signs(self)
    vim.fn.winrestview(prev.view)
    syncbind(self._annotate_win)
  end
end

local function mapkeys(self)
  local function map(mode, key, callback)
    vim.keymap.set(mode, key, callback, {
      noremap = true,
      buffer = self._annotate_buf,
    })
  end
  map('n', '<CR>', function()
    on_select(self)
  end)
  map('n', '<BS>', function()
    go_back(self)
  end)
  map('n', '<TAB>', ':CVSAnnotateNextHunk<CR>')
  map('n', '<S-TAB>', ':CVSAnnotatePrevHunk<CR>')
end

function Annotate.open(self)
  setup_window(self)
  setup_buffer(self)
  setup_popover(self)
  subscribe(self)
  mapkeys(self)
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
return function(opts)
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
    vim.api.nvim_win_call(win, function()
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
