return function(str)
  local result = {}
  for line in string.gmatch(str, '[^\r\n]+') do
    table.insert(result, line)
  end
  return result
end

