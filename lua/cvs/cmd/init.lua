local id = {
  log = 'CVSLog',
  diff = 'CVSDiff',
  annotate = 'CVSAnnotate',
  commit = 'CVSCommit',
}

return {
  id = id,
  diff = require("cvs.cmd.diff"),
  log = require('cvs.cmd.log'),
  commit = require('cvs.cmd.commit'),
  annotate = require('cvs.cmd.annotate'),
}

