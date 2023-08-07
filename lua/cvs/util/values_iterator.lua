return function(tbl, map_fn)
  local i = 0
  return function()
    i = i + 1
    if map_fn then
      return map_fn(tbl[i], i)
    else
      return tbl[i], i
    end
  end
end
