local action_state = require('telescope.actions.state')
local get_rev_date = require('cvs.utils.get_rev_date')

local function _telescope_diff(bufnr, files, opts)
  local telescope_diff = require('cvs.telescope.diff.picker')
  telescope_diff{
    files = files,
    opts = opts,
    from_log = true,
  }
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
  local files = picker.finder._files or {}
  _telescope_diff(bufnr, files, { rev_date = rev_date })
end

return {
  open_log_entry = open_log_entry,
  diff_commits = diff_commits,
}

