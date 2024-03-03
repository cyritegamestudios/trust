---------------------------
-- Condition checking whether the player has the given buffs.
-- @class module
-- @name HasBuffsCondition

local buff_util = require('cylibs/util/buff_util')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local HasBuffsCondition = setmetatable({}, { __index = Condition })
HasBuffsCondition.__index = HasBuffsCondition
HasBuffsCondition.__type = "HasBuffsCondition"
HasBuffsCondition.__class = "HasBuffsCondition"

function HasBuffsCondition.new(buff_names, num_required)
    local self = setmetatable(Condition.new(windower.ffxi.get_player().index), HasBuffsCondition)
    self.buff_names = buff_names -- save arg for serializer
    self.buff_ids = buff_names:map(function(buff_name) return buff_util.buff_id(buff_name)  end)
    self.num_required = num_required or buff_names:length()
    return self
end

function HasBuffsCondition.from_party_member(buff_names, num_required, party_member)
    local self = setmetatable(Condition.new(party_member:get_mob().index), HasBuffsCondition)
    self.buff_names = buff_names -- save arg for serializer
    self.buff_ids = buff_names:map(function(buff_name) return buff_util.buff_id(buff_name)  end)
    self.num_required = num_required or buff_names:length()
    self.party_member = party_member
    return self
end

function HasBuffsCondition:get_buff_count(buff_id, target_index)
    local buff_ids = L{}
    if target_index == windower.ffxi.get_player().index then
        buff_ids = L(windower.ffxi.get_player().buffs)
    else
        buff_ids = self.party_member:get_buff_ids()
    end
    return buff_util.buff_count(buff_id, buff_ids)
end

function HasBuffsCondition:is_satisfied(target_index)
    local num_active_buffs = 0
    local buff_ids = S(self.buff_ids)
    for buff_id in buff_ids:it() do
        num_active_buffs = num_active_buffs + self:get_buff_count(buff_id, target_index)
    end
    if num_active_buffs >= self.num_required then
        return true
    else
        return false
    end
end

function HasBuffsCondition:tostring()
    return "HasBuffsCondition"
end

function HasBuffsCondition:serialize()
    return "HasBuffsCondition.new(" .. serializer_util.serialize_args(self.buff_names, self.num_required) .. ")"
end

return HasBuffsCondition




