local run = require('cvs.sys.run')

local function cvs_remove(file)
  local temp = vim.fn.tempname()
  vim.fn.rename(file, temp)
  local _, code = run{
    "remove", file
  }
  vim.fn.rename(temp, file)
  if code > 0 then
    error('CVS REMOVE: failed to remove ' .. file)
  end
end

return function (files)
  for _, file in ipairs(files) do
    cvs_remove(file)
  end
end

