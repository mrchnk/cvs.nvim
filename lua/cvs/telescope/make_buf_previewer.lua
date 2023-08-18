local Previewer = require('telescope.previewers.previewer')
local fzy = require('telescope.algos.fzy')

local ns = vim.api.nvim_create_namespace('cvs_telescope_buf')
local higroup = 'TelescopePreviewMatch'

local function highlight(buf, matches)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(matches) do
    local row, col, len = unpack(m)
    vim.api.nvim_buf_add_highlight(buf, ns, higroup, row-1, col-1, col+len-1)
  end
end

local function preview_fn(self, entry, status)
  local buf = self.state.buf
  if not buf then
    return
  end
  self.state.win = status.preview_win
  self.state.entry = entry
  vim.api.nvim_win_set_buf(status.preview_win, buf)
  local prompt = status.picker:_get_prompt()
  local format_entry = self.state.format_entry
  local lines, matches = format_entry(entry, prompt)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  if matches then
    highlight(buf, matches)
  end
end

local function scroll_fn(self, direction)
  local win = self.state.win
  if not win then
    return
  end
  local input = direction > 0 and [[]] or [[]]
  local count = math.abs(direction)
  vim.api.nvim_win_call(win, function()
    vim.cmd([[normal! ]] .. count .. input)
  end)
end

local function on_picker_complete(self)
  local previewer = self.previewer
  local buf = previewer.state.buf
  local entry = previewer.state.entry
  if buf and entry then
    local prompt = self:_get_prompt()
    local format_entry = previewer.state.format_entry
    local _, matches = format_entry(entry, prompt)
    highlight(buf, matches)
  end
end


return function (opts)
  local previewer = Previewer:new{
    setup = function (self, status)
      local buf = vim.api.nvim_create_buf(false, true)
      status.picker:register_completion_callback(on_picker_complete)
      if opts.setup_buf then
        opts.setup_buf(buf)
      end
      return {
        buf = buf,
        format_entry = opts.format_entry,
      }
    end,
    teardown = function (self, status)
      local buf = self.state.buf
      vim.api.nvim_buf_delete(buf, {force = true})
      self.state = nil
    end,
    preview_fn = preview_fn,
    scroll_fn = scroll_fn,
  }
  return previewer
end
