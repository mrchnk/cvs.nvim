local cvs_hl = require('cvs.ui.highlight')
local AnnotateSign = {}

local annotate_sign = '┃'
local annotate_sign_id = 'CVSAnnotateRev'

function AnnotateSign.open(self, rev)
  if self._rev ~= rev then
    self._rev = rev
    vim.fn.sign_unplace(annotate_sign_id, {buffer = self.buf})
    if rev then
      local temp = self._temp[rev] or 0
      local signs = self._signs[rev]
      vim.fn.sign_define(annotate_sign_id, {
        text = annotate_sign,
        texthl = cvs_hl.get_annotate_fg(temp),
      })
      vim.fn.sign_placelist(signs)
    end
  end
end

function AnnotateSign.close(self)
  self:open(nil)
end

local function build(buf, annotate)
  local signs = vim.defaulttable()
  local temp = {}
  for idx, entry in ipairs(annotate) do
    if entry.rev then
      temp[entry.rev] = entry.temp
      table.insert(signs[entry.rev], {
        buffer = buf,
        name = annotate_sign_id,
        group = annotate_sign_id,
        lnum = idx,
      })
    end
  end
  return signs, temp
end

return function (opts)
  local buf = opts.buf
  local annotate = opts.annotate
  local signs, temp = build(buf, annotate)
  return setmetatable({
    buf = buf,
    _rev = nil,
    _signs = signs,
    _temp = temp,
  }, {
    __index = AnnotateSign,
  })
end

