local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local Previewer = require('telescope.previewers.previewer')

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
  local result = vim.fn.system('cvs diff -U 3')
  if vim.v.shell_error == 0 then
    error('No changes found')
  end
  return result
end

local function entry_maker(entry)
  return {
    value = entry,
    ordinal = entry.file,
    display = entry.file,
  }
end

local function make_previewer()
  return Previewer:new{
    setup = function (self, status)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(buf, 'syntax', 'diff')
      self._buf = buf
    end,
    teardown = function (self, status)
      local buf = self._buf
      vim.api.nvim_buf_delete(buf, {force = true})
    end,
    preview_fn = function (self, entry, status)
      local buf = self._buf
      vim.api.nvim_win_set_buf(status.preview_win, buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, entry.value.diff)
    end,
  }
end

local function on_select(bufnr)
  local entry = action_state.get_selected_entry()
  vim.print(entry)
end

return function (opts)
  local diff = diff_dir()
  local results = parse_diff(diff)
  pickers.new{
    prompt_title = "changed file",
    finder = finders.new_table{
      results = results,
      entry_maker = entry_maker,
    },
    preview_title = "diff",
    previewer = make_previewer(),
    attach_mappings = function(self, map)
      -- actions.select_default:replace(on_select)
      return true
    end
  }:find()
end
