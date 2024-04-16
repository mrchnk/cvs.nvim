return function (entries)
  local sorted = vim.tbl_extend('force', {}, entries)
  table.sort(sorted, function (a, b)
    return (a.ts or -1) < (b.ts or -1)
  end)
  local count = 0
  local last_rev
  for _, entry in ipairs(sorted) do
    if entry.rev then
      if entry.rev ~= last_rev then
        count = count + 1
        last_rev = entry.rev
      end
      entry.temp = count
    end
  end
  if count > 1 then
    for _, entry in ipairs(sorted) do
      if entry.rev then
        entry.temp = (entry.temp-1) / (count-1)
      end
    end
  end
end
