---------------------------
-- Wrapper class around an alliance member.
-- @class module
-- @name AllianceMember

local Entity = require('cylibs/entity/entity')

local AllianceMember = setmetatable({}, {__index = Entity })
AllianceMember.__index = AllianceMember
AllianceMember.__class = "AllianceMember"

-------
-- Default initializer for an AllianceMember.
-- @tparam number id Mob id
-- @tparam string name Mob name
-- @tparam number index Mob index
-- @tparam number party_index Party index (1, 2 or 3)
-- @treturn AllianceMemberMember An alliance member
function AllianceMember.new(id, index, zone_id, party_index)
    local self = setmetatable(Entity.new(id), AllianceMember)

    self.index = index
    self.zone_id = zone_id
    self.party_index = party_index

    return self
end

function AllianceMember:get_index()
    return self.index
end

function AllianceMember:get_zone_id()
    return self.zone_id
end

function AllianceMember:get_party_index()
    return self.party_index
end

return AllianceMember