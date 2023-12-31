local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local make_finder = require('cvs.telescope.log.finder')
local make_previewer = require('cvs.telescope.log.previewer')
local make_sorter = require('cvs.telescope.log.sorter')
local cvs_actions = require("cvs.telescope.log.actions")

local function attach_mappings(self, map)
  local modes = {'i', 'n'}
  actions.select_default:replace(cvs_actions.open_log_entry)
  map(modes, '<Leader>d', cvs_actions.diff_commits)
  return true
end

return function (opts)
  pickers.new{
    finder = make_finder(opts),
    sorter = make_sorter(),
    previewer = make_previewer(),
    attach_mappings = attach_mappings,
  }:find()
end

