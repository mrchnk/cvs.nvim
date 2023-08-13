local pickers = require('telescope.pickers')
local action_state = require('telescope.actions.state')
local ui_diff = require('cvs.ui.diff')
local cvs_diff = require('cvs.diff')

local function diff_file(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  local entry = action_state.get_selected_entry()
  pickers.on_close_prompt(bufnr)
  vim.api.nvim_set_current_win(picker.original_win_id)
  ui_diff(entry.value)
end

local function revert_file(bufnr)
  local entry = action_state.get_selected_entry()
  local file = entry.filename
  vim.cmd(string.format('!cvs up -C "%s"', file))
end

local function resume_picker(picker)
  -- this function is messing with telescope internals, may cause bugs in future
  picker.get_window_options = nil
  picker.layout_strategy = nil
  pickers.new({}, picker):find()
end

local function diff_commit(bufnr)
  local entry = action_state.get_selected_entry()
  local files = vim.tbl_map(function (file)
    return file.file
  end, entry.value.files)
  local ts = entry.value.ts
  local rev_date = {
    os.date('-D "%Y-%m-%d %H:%M:%S +0000"', ts-1),
    os.date('-D "%Y-%m-%d %H:%M:%S +0000"', ts),
  }
  local diff = cvs_diff(files, { rev_date = rev_date })
  local picker = action_state.get_current_picker(bufnr)
  local telescope_diff = require('cvs.telescope.diff')
  telescope_diff(diff, function ()
    resume_picker(picker)
  end)
end

local function go_back(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  if picker and type(picker._go_back) == 'function' then
    picker:_go_back(bufnr)
  end
end

return {
  diff_file = diff_file,
  revert_file = revert_file,
  diff_commit = diff_commit,
  go_back = go_back,
}

