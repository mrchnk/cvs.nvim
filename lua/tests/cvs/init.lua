local function test(module)
  require(module)
  print(module  .. ' - OK')
end

local function main()
  test('tests.cvs.diff_parse')
  test('tests.cvs.diff_unpatch')
end

main()
