local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local builtin = require('telescope.builtin')
local ui_diff = require('cvs.ui.diff')
local ui_commit = require('cvs.ui.commit')
local cvs_revert = require('cvs.revert')

local function diff_file(bufnr)
  local entry = action_state.get_selected_entry()
  actions.close(bufnr)
  ui_diff(entry.value)
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

local function go_back(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  if picker._from_log then
    builtin.resume()
  end
end

local function go_back_or_close(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  if picker._from_log then
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

return {
  go_back = go_back,
  go_back_or_close = go_back_or_close,
  go_back_backspace = go_back_backspace,
  diff_file = diff_file,
  revert_file = revert_file,
  commit_file = commit_file,
}

