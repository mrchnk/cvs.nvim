local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local make_finder = require('cvs.telescope.make_log_finder')
local make_previewer = require('cvs.telescope.make_log_previewer')
local make_sorter = require('cvs.telescope.make_log_sorter')
local cvs_actions = require("cvs.telescope.actions")
local make_attach_mappings = require('cvs.telescope.make_attach_mappings')
local get_conf = require('cvs').get_conf

local function attach_mappings(self, map)
  local modes = {'i', 'n'}
  actions.select_default:replace(cvs_actions.open_log_entry)
  map(modes, '<Leader>d', cvs_actions.diff_commits)
  return true
end

return function (opts)
  local picker = pickers.new{
    finder = make_finder(opts),
    sorter = make_sorter(),
    previewer = make_previewer(),
    attach_mappings = attach_mappings,
  }
  picker._cvs_opts = {
    results = opts.results,
    files = opts.files,
    opts = opts.opts,
  }
  picker:find()
end

