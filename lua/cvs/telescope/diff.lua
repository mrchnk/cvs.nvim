local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local actions = require('telescope.actions')
local make_finder = require('cvs.telescope.make_diff_finder')
local make_previewer = require('cvs.telescope.make_diff_previewer')
local cvs_actions = require("cvs.telescope.actions")

local function attach_mappings(self, map)
  map('i', '<C-d>', cvs_actions.diff_file)
  map('i', '<C-r>', cvs_actions.revert_file)
  map('i', '<C-j>', actions.preview_scrolling_down)
  map('i', '<C-k>', actions.preview_scrolling_up)
  return true
end

return function (diff_results, pp)
  pickers.new{
    finder = make_finder(diff_results),
    sorter = sorters.highlighter_only{},
    previewer = make_previewer(),
    attach_mappings = function (self, map)
      if pp then
        map('i', '<C-l>', function () pp:find() end)
      end
      attach_mappings(self, map)
      return true
    end,
  }:find()
end

