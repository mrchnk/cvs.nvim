local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local actions = require('telescope.actions')
local sorters = require('telescope.sorters')
local action_state = require('telescope.actions.state')
local Previewer = require('telescope.previewers.previewer')
local file_diff = require('cvs.file_diff')
local fzy = require('telescope.algos.fzy')

local ns = vim.api.nvim_create_namespace('cvs_telescope_diff')
local higroup = 'Visual'
--[[vim.api.nvim_set_hl(0, higroup, {
  fg = '#dcd7ba',
  bg = '#2d4f67',
  bold = true,
  default = false,
})]]

local function parse_diff(diff)
  local lines = vim.split(diff, "\n")
  local entry
  local result = {}
  local read_diff = false
  for _, line in ipairs(lines) do
    if vim.startswith(line, "cvs diff: Diffing ") then
      -- mac cvs header
    elseif vim.startswith(line, "Index: ") then
      local file = string.sub(line, 8)
      entry = {
        file = file,
        head = {},
        diff = {},
      }
      table.insert(result, entry)
      read_diff = false
    elseif vim.startswith(line, "diff ") then
      read_diff = true;
    end
    if entry then
      if read_diff then
        table.insert(entry.diff, line)
      else
        table.insert(entry.head, line)
      end
    end
  end
  return result
end

local function diff_dir()
  local result = vim.fn.system('cvs diff -U 3 -N')
  if vim.v.shell_error == 0 then
    error('No changes found')
  end
  return result
end

local function entry_maker(entry, matches)
  return {
    value = entry,
    filename = entry.file,
    ordinal = entry.file,
    display = entry.file,
    matches = matches,
  }
end

local function highlight(buf, matches)
  for _, m in ipairs(matches) do
    local row, col, len = unpack(m)
    vim.api.nvim_buf_add_highlight(buf, ns, higroup, row-1, col-1, col+len-1)
  end
end

local scroll_fn = function(self, direction)
  if not self._win then
    return
  end
  local input = direction > 0 and [[]] or [[]]
  local count = math.abs(direction)
  vim.api.nvim_win_call(self._win, function()
    vim.cmd([[normal! ]] .. count .. input)
  end)
end

local function make_previewer()
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
    preview_fn = function (self, entry, status)
      local buf = self._buf
      self._win = status.preview_win
      vim.api.nvim_win_set_buf(status.preview_win, buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, entry.value.diff)
      if entry.matches then
        highlight(buf, entry.matches)
      end
    end,
    scroll_fn = scroll_fn,
  }
end

local function on_select(bufnr)
  local entry = action_state.get_selected_entry()
  local file = entry.value.file
  local picker = action_state.get_current_picker(bufnr)
  pickers.on_close_prompt(bufnr)
  vim.api.nvim_set_current_win(picker.original_win_id)
  file_diff(file, {})
end

local function match(entry, prompt)
  if not prompt or prompt == "" then
    return true
  end
  local file_match = fzy.has_match(prompt, entry.file)
  local matches = {}
  for row, line in ipairs(entry.diff) do
    local col = string.find(line, prompt, 2)
    if col then
      table.insert(matches, {row, col, string.len(prompt)})
    end
  end
  return file_match or #matches > 0, matches
end


local function make_finder(results)
  return setmetatable({
    close = function () end,
  }, {
    __call = function (_, prompt, process_result, process_complete)
      for _, entry in ipairs(results) do
        local m, matches = match(entry, prompt)
        if m then
          process_result(entry_maker(entry, matches))
        end
      end
      process_complete()
    end,
  })
end

return function (opts)
  local diff = diff_dir()
  local results = parse_diff(diff)
  pickers.new{
    prompt_title = "changed file",
    finder = make_finder(results),
    sorter = sorters.highlighter_only{},
    preview_title = "diff",
    previewer = make_previewer(),
    attach_mappings = function(self, map)
      map('i', '<C-d>', on_select)
      map('i', '<C-j>', actions.preview_scrolling_down)
      map('i', '<C-k>', actions.preview_scrolling_up)
      return true
    end
  }:find()
end
