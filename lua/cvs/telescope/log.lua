local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local make_finder = require('cvs.telescope.make_log_finder')
local make_previewer = require('cvs.telescope.make_log_previewer')
local make_sorter = require('cvs.telescope.make_log_sorter')
local cvs_actions = require("cvs.telescope.actions")
local action_state = require('telescope.actions.state')
local cvs_diff = require('cvs.diff')
local telescope_diff = require('cvs.telescope.diff')

local function diff_commit(bufnr)
  local entry = action_state.get_selected_entry()
  local files = vim.tbl_map(function (file) 
    return file.file
  end, entry.value.files)
  local ts = entry.value.ts
  local date = {
    os.date('%Y-%m-%d %H:%M:%S +0000', ts-1),
    os.date('%Y-%m-%d %H:%M:%S +0000', ts),
  }
  local diff = cvs_diff(files, { date = date })
  local picker = action_state.get_current_picker(bufnr)
  telescope_diff(diff, picker)
end

local function attach_mappings(self, map)
  actions.select_default:replace(diff_commit)
  -- map('i', '<C-d>', diff_commit)
  -- map('i', '<C-r>', cvs_actions.revert_file)
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

