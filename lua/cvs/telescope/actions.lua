local pickers = require('telescope.pickers')
local action_state = require('telescope.actions.state')
local ui_diff = require('cvs.ui.diff')

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

return {
  diff_file = diff_file,
  revert_file = revert_file,
}

