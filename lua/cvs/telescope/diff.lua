local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local actions = require('telescope.actions')
local make_finder = require('cvs.telescope.make_diff_finder')
local make_previewer = require('cvs.telescope.make_diff_previewer')
local cvs_actions = require("cvs.telescope.actions")

local function attach_mappings(self, map)
  map('i', '<C-d>', cvs_actions.diff_file)
  map('i', '<C-r>', cvs_actions.revert_file)
  map('i', '<C-l>', cvs_actions.go_back)
  map('i', '<C-j>', actions.preview_scrolling_down)
  map('i', '<C-k>', actions.preview_scrolling_up)
  return true
end

return function (diff_results, go_back)
  local picker = pickers.new{
    finder = make_finder(diff_results),
    sorter = sorters.highlighter_only{},
    previewer = make_previewer(),
    attach_mappings = attach_mappings,
  }
  picker._go_back = go_back
  picker:find()
end

