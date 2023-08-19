return function (needle, table, begin)
  for i = begin or 1, #table do
    local lo_line = string.lower(table[i])
    if string.find(lo_line, needle, 1, true) then
      return true
    end
  end
  return false
end
