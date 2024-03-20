local run = require('cvs.sys.run')

local function cvs_add(file)
  return run({
    'add', file,
  }, { expecet_code = 0 })
end

return function (name)
  cvs_add(name)
end
