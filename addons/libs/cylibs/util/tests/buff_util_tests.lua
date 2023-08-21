TestBuffUtil = {}

function TestBuffUtil:setUp()
end

function TestBuffUtil:tearDown()
end

function TestBuffUtil:testBuffIdToName()
    local buff_name = buff_util.buff_name(173)
    luaunit.assertEquals(buff_name, 'Dread Spikess')
end