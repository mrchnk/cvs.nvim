local run = require('cvs.sys.run')

return function (files)
  return run({
    'up', '-C',
    files,
  }, { expect_code = 0, error_output = true, exec = true })
end

