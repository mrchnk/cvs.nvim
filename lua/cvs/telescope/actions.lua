local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local ui_diff = require('cvs.ui.diff')

local function diff_file(bufnr)
  local entry = action_state.get_selected_entry()
  actions.close(bufnr)
  ui_diff(entry.value)
end

local function revert_file(bufnr)
  local entry = action_state.get_selected_entry()
  local file = entry.filename
  vim.cmd(string.format('!cvs up -C "%s"', file))
end

local function _resume_picker(picker)
  -- this function is messing with telescope internals, may cause bugs in future
  picker.previewer.state = nil
  picker.get_window_options = nil
  picker.layout_strategy = nil
  picker:clear_completion_callbacks()
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
  local picker = action_state.get_current_picker(bufnr)
  local telescope_diff = require('cvs.telescope.diff')
  telescope_diff{
    files = files,
    opts = { rev_date = rev_date },
    go_back = function ()
      _resume_picker(picker)
    end,
  }
end

local function go_back(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  if picker and picker._go_back then
    picker:_go_back(bufnr)
  end
end

local function go_back_backspace(bufnr)
  if action_state.get_current_line() == '' then
    go_back(bufnr)
  else
    local keys = vim.api.nvim_replace_termcodes("<bs>", true, false, true)
    vim.api.nvim_feedkeys(keys, "tn", false)
  end
end

return {
  diff_file = diff_file,
  revert_file = revert_file,
  diff_commit = diff_commit,
  go_back = go_back,
  go_back_backspace = go_back_backspace,
}

