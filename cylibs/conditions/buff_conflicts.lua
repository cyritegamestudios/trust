---------------------------
-- Condition checking whether a buff conflicts with a party member's current buffs.
-- @class module
-- @name BuffConflictsCondition

local buff_util = require('cylibs/util/buff_util')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local BuffConflictsCondition = setmetatable({}, { __index = Condition })
BuffConflictsCondition.__index = BuffConflictsCondition
BuffConflictsCondition.__type = "BuffConflictsCondition"
BuffConflictsCondition.__class = "BuffConflictsCondition"

function BuffConflictsCondition.new(buff_name, target_index)
    local self = setmetatable(Condition.new(target_index), BuffConflictsCondition)
    self.buff_name = buff_name or "Refresh"
    return self
end

function BuffConflictsCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(self:get_target_index() or target_index)
    if target then
        local party_member = player.alliance:get_alliance_member_named(target.name)
        if party_member then
            local buff_id = buff_util.buff_id(self.buff_name)
            return buff_id and buff_util.conflicts_with_buffs(buff_id, party_member:get_buff_ids())
        end
    end
    return false
end

function BuffConflictsCondition:tostring()
    return i18n.resource_long('buffs', 'en', self.buff_name).." conflicts with buffs"
end

function BuffConflictsCondition.description()
    return "Conflicts with buffs."
end

function BuffConflictsCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function BuffConflictsCondition:serialize()
    return "BuffConflictsCondition.new(" .. serializer_util.serialize_args(self.buff_name) .. ")"
end

return BuffConflictsCondition




