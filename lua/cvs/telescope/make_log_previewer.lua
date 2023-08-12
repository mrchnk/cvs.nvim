local Previewer = require('telescope.previewers.previewer')

local function format_commit(commit)
  local lines = {
    string.format('Author: %s', commit.author),
    string.format('Date:   %s', commit.date),
    '',
  }
  for _, line in ipairs(commit.message) do
    table.insert(lines, '    ' .. line)
  end
  table.insert(lines, '')
  local max_file_len = math.max(unpack(vim.tbl_map(function (file)
    return #file.file
  end, commit.files)))
  for _, file in ipairs(commit.files) do
    table.insert(lines, string.format('  %-' .. max_file_len .. 's  -r%s', file.file, file.rev))
  end
  table.insert(lines, string.format('  %s file(s) changed', #commit.files))
  return lines
end

local function preview_fn(self, entry, status)
  local buf = self._buf
  self._win = status.preview_win
  vim.api.nvim_win_set_buf(status.preview_win, buf)
  local lines = format_commit(entry.value)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
end

local function scroll_fn(self, direction)
  if not self._win then
    return
  end
  local input = direction > 0 and [[]] or [[]]
  local count = math.abs(direction)
  vim.api.nvim_win_call(self._win, function()
    vim.cmd([[normal! ]] .. count .. input)
  end)
end

return function ()
  return Previewer:new{
    setup = function (self, status)
      if not self._buf then
        local buf = vim.api.nvim_create_buf(false, true)
        self._buf = buf
      end
    end,
    teardown = function (self, status)
      if self._buf then
        local buf = self._buf
        vim.api.nvim_buf_delete(buf, {force = true})
        self._buf = nil
      end
    end,
    preview_fn = preview_fn,
    scroll_fn = scroll_fn,
  }
end
