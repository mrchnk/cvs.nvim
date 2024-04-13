return function (entries)
  local sorted = vim.tbl_extend('force', {}, entries)
  table.sort(sorted, function (a, b)
    if not a.ts then return true end
    if not b.ts then return false end
    return a.ts < b.ts
  end)
  local count = 0
  local last_rev
  for _, entry in ipairs(sorted) do
    if entry.rev then
      entry.temp = count
      if entry.rev ~= last_rev then
        last_rev = entry.rev
        count = count + 1
      end
    end
  end
  vim.print({ c = count, l = last_rev })
  if count > 1 then
    for _, entry in ipairs(sorted) do
      if entry.temp then
        entry.temp = entry.temp / count
      end
    end
  end
end
