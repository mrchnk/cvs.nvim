local Previewer = require('telescope.previewers.previewer')
local fzy = require('telescope.algos.fzy')

local ns = vim.api.nvim_create_namespace('cvs_telescope_log')
local higroup = 'TelescopePreviewMatch'

local function find_words(prompt, line)
  local words = vim.gsplit(prompt, '%s+', {trimempty=true})
  local word = words()
  local pos = 0
  return function ()
    while word do
      pos = string.find(line, word, pos+1)
      if pos then
        return pos, #word
      end
      word = words()
      pos = 0
    end
  end
end

local function format_commit(commit, prompt)
  local lines = {
    string.format('Author: %s', commit.author),
    string.format('Date:   %s', commit.date),
    '',
  }
  local matches = {}
  if prompt == commit.author then
    table.insert(matches, {1, 9, #commit.author})
  end
  for _, line in ipairs(commit.message) do
    table.insert(lines, '    ' .. line)
    for pos, len in find_words(prompt, line) do
      table.insert(matches, {#lines, pos+4, len})
    end
  end
  table.insert(lines, '')
  local max_file_len = math.max(unpack(vim.tbl_map(function (file)
    return #file.file
  end, commit.files)))
  for _, file in ipairs(commit.files) do
    table.insert(lines, string.format('  %-' .. max_file_len .. 's  -r%s', file.file, file.rev))
    for _, pos in ipairs(fzy.positions(prompt, file.file)) do
      table.insert(matches, {#lines, pos+2, 1})
    end
  end
  table.insert(lines, string.format('  %s file(s) changed', #commit.files))
  return lines, matches
end

local function highlight(buf, matches)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(matches) do
    local row, col, len = unpack(m)
    vim.api.nvim_buf_add_highlight(buf, ns, higroup, row-1, col-1, col+len-1)
  end
end

local function preview_fn(self, entry, status)
  local buf = self._buf
  self._win = status.preview_win
  self._entry = entry
  vim.api.nvim_win_set_buf(status.preview_win, buf)
  local prompt = status.picker:_get_prompt()
  local lines, matches = format_commit(entry.value, prompt)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  highlight(buf, matches)
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

local function on_picker_complete(self)
  local prompt = self:_get_prompt()
  local previewer = self.previewer;
  local entry = previewer._entry
  local buf = previewer._buf
  if buf and entry then
    local _, matches = format_commit(entry.value, prompt)
    highlight(buf, matches)
  end
end

return function ()
  local subscribed
  return Previewer:new{
    setup = function (self, status)
      if not self._buf then
        local buf = vim.api.nvim_create_buf(false, true)
        self._buf = buf
      end
      if not subscribed then
        subscribed = true
        status.picker:register_completion_callback(on_picker_complete)
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
