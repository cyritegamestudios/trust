---------------------------
-- Condition checking whether the player, party member or enemy has a debuff.
-- @class module
-- @name HasDebuffCondition

local buff_util = require('cylibs/util/buff_util')
local party_util = require('cylibs/util/party_util')
local serializer_util = require('cylibs/util/serializer_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local StatusAilment = require('cylibs/battle/status_ailment')

local Condition = require('cylibs/conditions/condition')
local HasDebuffCondition = setmetatable({}, { __index = Condition })
HasDebuffCondition.__index = HasDebuffCondition
HasDebuffCondition.__type = "HasDebuffCondition"
HasDebuffCondition.__class = "HasDebuffCondition"

function HasDebuffCondition.new(debuff_name, target_index)
    local self = setmetatable(Condition.new(target_index), HasDebuffCondition)
    self.debuff_name = debuff_name or "poison"
    self.debuff_id = buff_util.buff_id(self.debuff_name)
    return self
end

function HasDebuffCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(self:get_target_index() or target_index)
    if target then
        local monster = player.alliance:get_target_by_index(target.index)
        if monster then
            return monster:has_debuff(self.debuff_id)
        else
            local party_member = player.alliance:get_alliance_member_named(target.name)
            if party_member then
                return S(party_member:get_debuff_ids()):contains(self.debuff_id)
            end
        end
    end
    return false
end

function HasDebuffCondition:get_config_items()
    local all_debuffs = L(S(L(buff_util.get_all_debuff_ids()):map(function(debuff_id)
        if res.buffs[debuff_id] then
            return res.buffs[debuff_id].en
        end
        return nil
    end):compact_map()))
    return L{
        PickerConfigItem.new('debuff_name', self.debuff_name, all_debuffs, function(debuff_name)
            local status_ailment = StatusAilment.new(debuff_name)
            return status_ailment:get_localized_name()
        end, "Status Ailment")
    }
end

function HasDebuffCondition:tostring()
    return "Is "..res.buffs:with('en', self.debuff_name).enl
end

function HasDebuffCondition.description()
    return "Has debuff."
end

function HasDebuffCondition.valid_targets()
    return Condition.TargetType.AllTargets
end

function HasDebuffCondition:serialize()
    return "HasDebuffCondition.new(" .. serializer_util.serialize_args(self.debuff_name) .. ")"
end

function HasDebuffCondition:__eq(otherItem)
    return otherItem.__class == HasDebuffCondition.__class
            and otherItem.debuff_name == self.debuff_name
end

return HasDebuffCondition




