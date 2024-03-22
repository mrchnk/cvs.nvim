local run = require('cvs.sys.run')

return function (files, opts)
  return run({
    'commit',
    opts.message and { '-m', opts.message } or {},
    opts.message_file and { '-F', opts.message_file } or {},
    files,
  }, { exec = true })
end
