local run = require('cvs.sys.run')

local function cvs_up(files)
  local lines, code = run{
    'up', '-C',
    files,
  }
  if code > 0 then
    error('CVS UP: failed to revert files ' .. table.concat(files, ', '))
  end
  vim.fn.input(table.concat(vim.tbl_flatten{
    '!cvs up -C ' .. table.concat(files, ' '),
    lines,
    'Press ENTER...'}, '\n'))
end

return function (files, opts)
  cvs_up(files)
end

