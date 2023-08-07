local diff = require('cvs.diff')
local assert_deep_equals = require('tests.cvs.assert_deep_equals')

local function test(lines_after, lines_patch, lines_before)
  local patch = diff.parse(lines_patch)
  local result = diff.unpatch(lines_after, patch)
  assert_deep_equals(result, lines_before)
end

test(
  {'aaa'},
  {'2d1', '< bbb'},
  {'aaa', 'bbb'})

test(
  {'aaa'},
  {'1d0', '< bbb'},
  {'bbb', 'aaa'})

test(
  {},
  {'1d0', '< aaa'},
  {'aaa'})

test(
  {'aaa'},
  {'1c1', '< bbb', '---', '> aaa'},
  {'bbb'})

test(
  {'aaa'},
  {'0a1', '> aaa'},
  {})

test(
  {'aaa'},
  {'0a1', '> aaa'},
  {})

test(
  {},
  {'1d0', '< aaa'},
  {'aaa'})
