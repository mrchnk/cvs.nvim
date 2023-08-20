local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local make_finder = require('cvs.telescope.diff.finder')
local make_previewer = require('cvs.telescope.diff.previewer')
local make_sorter = require('cvs.telescope.diff.sorter')
local cvs_actions = require('cvs.telescope.diff.actions')

local function attach_mappings(self, map)
  local modes = {'i', 'n'}
  actions.select_default:replace(cvs_actions.open_file)
  actions.select_vertical:replace(cvs_actions.open_file_vertical)
  actions.select_horizontal:replace(cvs_actions.open_file_horizontal)
  actions.select_tab:replace(cvs_actions.open_file_tab)
  map('i', '<BS>', cvs_actions.go_back_backspace)
  map('n', '<BS>', cvs_actions.go_back)
  map(modes, '<Leader>c', cvs_actions.commit_file)
  map(modes, '<Leader>d', cvs_actions.diff_file)
  map(modes, '<Leader>r', cvs_actions.revert_file)
  map(modes, '<Leader>a', cvs_actions.add_file)
  return true
end

return function (opts)
  local cache_picker
  if opts.from_log then
    cache_picker = false
  end
  pickers.new{
    finder = make_finder(opts),
    sorter = make_sorter(),
    previewer = make_previewer(),
    attach_mappings = attach_mappings,
    cache_picker = cache_picker
  }:find()
end

