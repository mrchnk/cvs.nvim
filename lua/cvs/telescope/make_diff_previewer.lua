local Previewer = require('telescope.previewers.previewer')

local ns = vim.api.nvim_create_namespace('cvs_telescope_diff')
local higroup = 'TelescopePreviewMatch'

local function highlight(buf, matches)
  for _, m in ipairs(matches) do
    local row, col, len = unpack(m)
    vim.api.nvim_buf_add_highlight(buf, ns, higroup, row-1, col-1, col+len-1)
  end
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

local function preview_fn(self, entry, status)
  local buf = self._buf
  self._win = status.preview_win
  vim.api.nvim_win_set_buf(status.preview_win, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, entry.value.body)
  if entry.matches then
    highlight(buf, entry.matches)
  end
end

return function ()
  return Previewer:new{
    setup = function (self, status)
      if not self._buf then
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf, 'syntax', 'diff')
        self._buf = buf
      end
    end,
    teardown = function (self, status)
      if self._buf then
        local buf = self._buf
        vim.api.nvim_buf_delete(buf, {force = true})
      end
    end,
    preview_fn = preview_fn,
    scroll_fn = scroll_fn,
  }
end
