return function (tbl, prefix)
  if not tbl or #tbl == 0 then
    return ''
  end
  return table.concat(vim.tbl_map(function (value)
    if prefix then
      return string.format('%s "%s"', prefix, value)
    else
      return string.format('"%s"', value)
    end
  end, tbl), ' ')
end

