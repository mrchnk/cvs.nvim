local diff = require('cvs.diff')
local assert_deep_equals = require('tests.cvs.assert_deep_equals')

local function test(lines, commands)
  assert_deep_equals(diff.parse(lines), commands)
end

test({
  '3a6',
  '> xxx',
}, {
  {'a', {3, {6,6}}, {{}, {'xxx'}}},
})

test({
  '3c6',
  '> xxx',
  '---',
  '< yyy'
}, {
  {'c', {{3, 3}, {6,6}}, {{'xxx'}, {'yyy'}}},
})

test({
  '3d6',
  '< yyy'
}, {
  {'d', {{3, 3}, 6}, {{'yyy'}, {}}},
})
