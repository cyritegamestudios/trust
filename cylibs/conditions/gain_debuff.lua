---------------------------
-- Condition checking whether the player, party member or enemy gains a debuff.
-- @class module
-- @name GainDebuffCondition

local buff_util = require('cylibs/util/buff_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')
local StatusAilment = require('cylibs/battle/status_ailment')

local Condition = require('cylibs/conditions/condition')
local GainDebuffCondition = setmetatable({}, { __index = Condition })
GainDebuffCondition.__index = GainDebuffCondition
GainDebuffCondition.__type = "GainDebuffCondition"
GainDebuffCondition.__class = "GainDebuffCondition"

function GainDebuffCondition.new(debuff_name, target_index)
    local self = setmetatable(Condition.new(target_index), GainDebuffCondition)
    self.debuff_name = debuff_name or "poison"
    self.debuff_id = buff_util.buff_id(self.debuff_name)
    return self
end

function GainDebuffCondition:is_satisfied(target_index, debuff_name)
    return self.debuff_name == debuff_name
end

function GainDebuffCondition:get_config_items()
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

function GainDebuffCondition:tostring()
    return "Is now "..i18n.resource_long('buffs', 'en', self.debuff_name)
end

function GainDebuffCondition.description()
    return "Gain debuff."
end

function GainDebuffCondition.valid_targets()
    return Condition.TargetType.AllTargets
end

function GainDebuffCondition:serialize()
    return "GainDebuffCondition.new(" .. serializer_util.serialize_args(self.debuff_name) .. ")"
end

return GainDebuffCondition




