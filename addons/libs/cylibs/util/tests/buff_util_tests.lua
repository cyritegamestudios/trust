function testBuffIdToName()
    local buff_name = buff_util.buff_name(173)
    luaunit.assertEquals(buff_name, 'Dread Spikes')
end