return function (list)
  return function (self, map)
    for i = 1, #list do
      local attach_mappings = list[i]
      if attach_mappings then
        local continue = attach_mappings(self, map)
        if not continue then
          return false
        end
      end
    end
    return true
  end
end
