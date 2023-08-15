local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local ui_diff = require('cvs.ui.diff')
local cvs_revert = require('cvs.revert')

local function get_rev_date(ts)
  return os.date('-D "%Y-%m-%d %H:%M:%S +0000"', ts)
end

local function _resume_picker(picker)
  -- this function is messing with telescope internals, may cause bugs in future
  picker.previewer.state = nil
  picker.get_window_options = nil
  picker.layout_strategy = nil
  picker:clear_completion_callbacks()
  pickers.new({}, picker):find()
end

local function _telescope_diff(bufnr, files, opts)
  local picker = action_state.get_current_picker(bufnr)
  local telescope_diff = require('cvs.telescope.diff')
  telescope_diff{
    files = files,
    opts = opts,
    go_back = function ()
      _resume_picker(picker)
    end,
  }
end

local function diff_file(bufnr)
  local entry = action_state.get_selected_entry()
  actions.close(bufnr)
  ui_diff(entry.value)
end

local function diff_commits(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  local entries = picker:get_multi_selection()
  local left, right
  if #entries == 2 then
    left, right = entries[1].value, entries[2].value
  elseif #entries == 1 then
    left = entries[1].value
    right = action_state.get_selected_entry().value
  else
    error('Select two diffferent entries')
  end
  if left == right then
    error('Select two diffferent entries')
  end
  if left.ts > right.ts then
    left, right = right, left
  end
  local rev_date = {
    get_rev_date(left.ts),
    get_rev_date(right.ts),
  }
  _telescope_diff(bufnr, {}, { rev_date = rev_date })
end

local function revert_file(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  local entries = picker:get_multi_selection()
  if #entries == 0 then
     entries = {action_state.get_selected_entry()}
  end
  local files = vim.tbl_map(function (entry)
    return entry.value.file
  end, entries)
  cvs_revert(files)
end


local function open_log_entry(bufnr)
  local entry = action_state.get_selected_entry()
  local files = vim.tbl_map(function (file)
    return file.file
  end, entry.value.files)
  local ts = entry.value.ts
  local rev_date = {
    get_rev_date(ts-1),
    get_rev_date(ts),
  }
  _telescope_diff(bufnr, files, { rev_date = rev_date })
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
  diff_commits = diff_commits,
  revert_file = revert_file,
  open_log_entry = open_log_entry,
  go_back = go_back,
  go_back_backspace = go_back_backspace,
}

