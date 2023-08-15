local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local make_finder = require('cvs.telescope.make_log_finder')
local make_previewer = require('cvs.telescope.make_log_previewer')
local make_sorter = require('cvs.telescope.make_log_sorter')
local cvs_actions = require("cvs.telescope.actions")

local function attach_mappings(self, map)
  local modes = {'i', 'n'}
  actions.select_default:replace(cvs_actions.open_log_entry)
  map(modes, '<C-D>', cvs_actions.diff_commits)
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
  picker._cvs_opts = opts
  picker:find()
end

