local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local builtin = require('telescope.builtin')
local transform_mod = require('telescope.actions.mt').transform_mod
local ui_diff = require('cvs.ui.diff')
local ui_commit = require('cvs.ui.commit')
local cvs_revert = require('cvs.revert')

local function get_rev_date(ts)
  return os.date('-D "%Y-%m-%d %H:%M:%S +0000"', ts)
end

local function _telescope_diff(bufnr, files, opts)
  local telescope_diff = require('cvs.telescope.diff')
  telescope_diff{
    files = files,
    opts = opts,
    from_log = true,
  }
end

local function diff_file(bufnr)
  local entry = action_state.get_selected_entry()
  actions.close(bufnr)
  ui_diff(entry.value)
end

local function diff_commits(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  local opts = picker._cvs_opts or {}
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
  local files = opts.files or {}
  _telescope_diff(bufnr, files, { rev_date = rev_date })
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
  if picler._from_log then
    builtin.resume()
  end
end

local function go_back_or_close(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  if picler._from_log then
    builtin.resume()
  else
    actions.close(bufnr)
  end
end

local function go_back_backspace(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  if action_state.get_current_line() == '' then
    if picker._from_log then
      builtin.resume()
    end
  else
    local keys = vim.api.nvim_replace_termcodes("<bs>", true, false, true)
    vim.api.nvim_feedkeys(keys, "tn", false)
  end
end

local function commit_file(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  local entries = picker:get_multi_selection()
  if #entries == 0 then
     entries = {action_state.get_selected_entry()}
  end
  local files = vim.tbl_map(function (entry)
    return entry.value.file
  end, entries)
  actions.close(bufnr)
  ui_commit(files, {
    go_back = function ()
      builtin.resume()
    end
  })
end

return transform_mod{
  diff_file = diff_file,
  diff_commits = diff_commits,
  revert_file = revert_file,
  open_log_entry = open_log_entry,
  go_back_backspace = go_back_backspace,
  go_back_or_close = go_back_or_close,
  commit_file = commit_file,
}

