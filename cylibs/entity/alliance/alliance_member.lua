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
-- @tparam number index Mob index
-- @tparam number zone_id Zone id
-- @treturn AllianceMemberMember An alliance member
function AllianceMember.new(id, index, zone_id)
    local self = setmetatable(Entity.new(id), AllianceMember)

    self.index = index
    self.zone_id = zone_id

    return self
end

function AllianceMember:get_index()
    return self.index
end

function AllianceMember:get_zone_id()
    return self.zone_id
end

return AllianceMember