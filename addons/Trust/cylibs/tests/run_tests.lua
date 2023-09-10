luaunit = require('cylibs/tests/luaunit')

-- Import tests from submodules, relative to cylibs folder
require('cylibs/util/tests/buff_util_tests')

function run_unit_tests()
    luaunit.LuaUnit.run()
end

