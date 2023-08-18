local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local make_finder = require('cvs.telescope.make_diff_finder')
local make_previewer = require('cvs.telescope.make_diff_previewer')
local make_sorter = require('cvs.telescope.make_diff_sorter')
local cvs_actions = require('cvs.telescope.actions')
local make_attach_mappings = require('cvs.telescope.make_attach_mappings')
local get_conf = require('cvs').get_conf

local function attach_mappings(self, map)
  local modes = {'i', 'n'}
  map('i', '<BS>', cvs_actions.go_back_backspace)
  map('n', '<BS>', cvs_actions.go_back)
  map(modes, '<Leader>c', cvs_actions.commit_file)
  map(modes, '<Leader>d', cvs_actions.diff_file)
  map(modes, '<Leader>r', cvs_actions.revert_file)
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

