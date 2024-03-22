local run = require('cvs.sys.run')

return function (files, opts)
  return run({
    '-U', opts.context or 3,
    files,
  }, { cmd = 'diff' })
end
