local cmd_id = require('cvs.cmd.id')

local function close(self)
  self:close()
end

local function jump(lnum)
  local win = vim.api.nvim_get_current_win()
  vim.cmd("normal! m'")
  vim.api.nvim_win_set_cursor(win, { lnum, 1 })
end

local function next_hunk(self)
  local entries = self._meta
  local entry, lnum = self:get_cur_entry()
  local rev = entry.rev
  if entries and rev then
    local same = true
    for i = lnum + 1, #entries do
      if same and entries[i].rev ~= rev then
        same = false
      elseif not same and entries[i].rev == entry.rev then
        return jump(i)
      end
    end
  end
end

local function prev_hunk(self)
  local entries = self._meta
  local entry, lnum = self:get_cur_entry()
  local rev = entry.rev
  if entries and rev then
    local same = true
    for i = lnum - 1, 1, -1 do
      if same and entries[i].rev ~= rev then
        same = false
      elseif not same and entries[i].rev == entry.rev then
        return jump(i)
      end
    end
  end
end

local commands = {
  {cmd_id.annotate, close},
  {cmd_id.annotate_next_hunk, next_hunk},
  {cmd_id.annotate_prev_hunk, prev_hunk},
}

return function (self)
  local i = 0
  return function ()
    i = i + 1
    local pair = commands[i]
    if not pair then
      return nil
    end
    local name, callback = unpack(pair)
    return name, function ()
      callback(self)
    end
  end
end
