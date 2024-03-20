local run = require('cvs.sys.run')

local function cvs_up(file, rev)
  return run({
    '-nq', 'up',
    '-p',
    '-r', rev,
    file
  }, { expect_code = 0 })
end

return function (file, rev)
  local body = cvs_up(file, rev)
  return {
    file = file,
    rev = rev,
    head = {},
    body = body,
  }
end

