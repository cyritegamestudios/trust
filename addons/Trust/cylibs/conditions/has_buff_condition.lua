---------------------------
-- Condition checking whether the player or party member has a buff.
-- @class module
-- @name HasBuffCondition

local buff_util = require('cylibs/util/buff_util')
local party_util = require('cylibs/util/party_util')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local HasBuffCondition = setmetatable({}, { __index = Condition })
HasBuffCondition.__index = HasBuffCondition
HasBuffCondition.__type = "HasBuffCondition"

function HasBuffCondition.new(buff_name, target_index)
    local self = setmetatable(Condition.new(target_index), HasBuffCondition)
    self.buff_name = buff_name
    self.buff_id = buff_util.buff_id(buff_name)
    return self
end

function HasBuffCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return L(party_util.get_buffs(target.id)):contains(self.buff_id)
    end
    return false
end

function HasBuffCondition:tostring()
    return "HasBuffCondition"
end

function HasBuffCondition:serialize()
    return "HasBuffCondition.new(" .. serializer_util.serialize_args(self.buff_name) .. ")"
end

return HasBuffCondition




