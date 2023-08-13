local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local make_finder = require('cvs.telescope.make_log_finder')
local make_previewer = require('cvs.telescope.make_log_previewer')
local make_sorter = require('cvs.telescope.make_log_sorter')
local cvs_actions = require("cvs.telescope.actions")

local function attach_mappings(self, map)
  actions.select_default:replace(cvs_actions.diff_commit)
  map('i', '<C-j>', actions.preview_scrolling_down)
  map('i', '<C-k>', actions.preview_scrolling_up)
  return true
end

return function (log)
  pickers.new{
    finder = make_finder(log),
    sorter = make_sorter(),
    previewer = make_previewer(),
    attach_mappings = attach_mappings,
  }:find()
end

