local sorters = require('telescope.sorters')

local function scoring_fn(self, prompt, ordinal, entry)
  return 1/entry.value.ts
end

local function filter_fn(self, prompt, entry)
  return 1, prompt
end

return function ()
  return sorters.Sorter:new{
    scoring_function = scoring_fn,
    filter_function = filter_fn,
  } -- and sorters.get_fzy_sorter()
end
