local Popover = {}

function Popover.move_to(self, col, row)
end

function Popover.set_text(self, lines)
  local buf = self._buf
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
end

function Popover.open(self)
  if not self._win and not self._buf then
    local buf = vim.api.nvim_create_buf(false, true)
    local width = 88
    local height = 6
    local conf = {
      --relative = 'win',
      --win = self.win,
      relative = 'editor',
      width = width,
      height = height,
      border = 'single',
      title = 'Commit info',
      style = 'minimal',
      col = (vim.o.columns - width) / 2,
      row = (vim.o.lines - height) / 2,
    }
    local win = vim.api.nvim_open_win(buf, false, conf)
    self._buf = buf
    self._win = win
  end
end

function Popover.close(self)
  if self._win and self._buf then
    vim.api.nvim_win_close(self._win, true)
    vim.api.nvim_buf_delete(self._buf, { force = true })
    self._win = nil
    self._buf = nil
  end
end

return function(opts)
  local win = opts.win or vim.api.nvim_get_current_win()
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  return setmetatable({
    buf = buf,
    win = win,
  }, { __index = Popover })
end
