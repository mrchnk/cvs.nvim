local pickers = require('telescope.pickers')
local action_state = require('telescope.actions.state')
local sorters = require('telescope.sorters')
local actions = require('telescope.actions')
local ui_diff = require('cvs.ui.diff')
local make_finder = require('cvs.telescope.make_diff_finder')
local make_previewer = require('cvs.telescope.make_diff_previewer')

local function diff_file(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  local entry = action_state.get_selected_entry()
  pickers.on_close_prompt(bufnr)
  vim.api.nvim_set_current_win(picker.original_win_id)
  ui_diff(entry.value)
end

local function revert_file(bufnr)
  local entry = action_state.get_selected_entry()
  local file = entry.filename
  vim.cmd(string.format('!cvs up -C "%s"', file))
end

local function attach_mappings(self, map)
  map('i', '<C-d>', diff_file)
  map('i', '<C-r>', revert_file)
  map('i', '<C-j>', actions.preview_scrolling_down)
  map('i', '<C-k>', actions.preview_scrolling_up)
  return true
end

return function (diff_results)
  pickers.new{
    finder = make_finder(diff_results),
    sorter = sorters.highlighter_only{},
    previewer = make_previewer(),
    attach_mappings = attach_mappings,
  }:find()
end
