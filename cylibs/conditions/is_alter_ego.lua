---------------------------
-- Condition checking whether the target is an Alter Ego.
-- @class module
-- @name IsAlterEgoCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local IsAlterEgoCondition = setmetatable({}, { __index = Condition })
IsAlterEgoCondition.__index = IsAlterEgoCondition
IsAlterEgoCondition.__type = "IsAlterEgoCondition"
IsAlterEgoCondition.__class = "IsAlterEgoCondition"

function IsAlterEgoCondition.new(is_alter_ego)
    local self = setmetatable(Condition.new(), IsAlterEgoCondition)
    self.is_alter_ego = false
    return self
end

function IsAlterEgoCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party = player.party
        if party then
            local party_member = party:get_party_member(target.id)
            if party_member then
                return party_member:is_trust()
            end
        end
    end
    return false
end

function IsAlterEgoCondition:get_config_items()
    return L{
        BooleanConfigItem.new('is_alter_ego', 'Is Alter Ego')
    }
end

function IsAlterEgoCondition:tostring()
    return "Is alter ego"
end

function IsAlterEgoCondition.description()
    return "Is alter ego."
end

function IsAlterEgoCondition.valid_targets()
    return S{ Condition.TargetType.Ally }
end

function IsAlterEgoCondition:serialize()
    return "IsAlterEgoCondition.new(" .. serializer_util.serialize_args(self.is_alter_ego) .. ")"
end

return IsAlterEgoCondition




