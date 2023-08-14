local fzy = require('telescope.algos.fzy')

return function (needle, files, begin)
  for i = begin or 1, #files do
    local file = files[i].file
    if fzy.has_match(needle, file) then
      return true
    end
  end
  return false
end
