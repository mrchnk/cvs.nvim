return function (needle, histack)
  local words = vim.gsplit(needle, '%s+', {trimempty=true})
  local word = words()
  local pos = 0
  return function ()
    while word do
      pos = string.find(histack, word, pos+1, true)
      if pos then
        return pos, #word
      end
      word = words()
      pos = 0
    end
  end
end

