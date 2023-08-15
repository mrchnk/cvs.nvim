local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local make_finder = require('cvs.telescope.make_diff_finder')
local make_previewer = require('cvs.telescope.make_diff_previewer')
local make_sorter = require('cvs.telescope.make_diff_sorter')
local cvs_actions = require("cvs.telescope.actions")

local function attach_mappings(self, map)
  local modes = {'i', 'n'}
  map(modes, '<BS>', cvs_actions.go_back_backspace)
  map(modes, '<C-D>', cvs_actions.diff_file)
  map(modes, '<C-G>', cvs_actions.go_back)
  map(modes, '<C-R>', cvs_actions.revert_file)
  map(modes, '<C-J>', actions.preview_scrolling_down)
  map(modes, '<C-K>', actions.preview_scrolling_up)
  return true
end

return function (opts)
  local picker = pickers.new{
    finder = make_finder(opts),
    sorter = make_sorter(),
    previewer = make_previewer(),
    attach_mappings = attach_mappings,
  }
  picker._go_back = opts.go_back
  picker:find()
end

