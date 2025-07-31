---------------------------
-- Condition checking whether the player or party member has a status effect.
-- @class module
-- @name HasStatusEffectCondition

local serializer_util = require('cylibs/util/serializer_util')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local StatusAilment = require('cylibs/battle/status_ailment')

local Condition = require('cylibs/conditions/condition')
local HasStatusEffectCondition = setmetatable({}, { __index = Condition })
HasStatusEffectCondition.__index = HasStatusEffectCondition
HasStatusEffectCondition.__type = "HasStatusEffectCondition"
HasStatusEffectCondition.__class = "HasStatusEffectCondition"

function HasStatusEffectCondition.new(status_id)
    local self = setmetatable(Condition.new(), HasStatusEffectCondition)
    self.status_id = status_id or 33
    return self
end

function HasStatusEffectCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(self:get_target_index() or target_index)
    if target then
        local party_member = player.alliance:get_alliance_member_named(target.name)
        if party_member then
            return party_member:get_buff_ids():contains(self.status_id)
        end
    end
    return false
end

function HasStatusEffectCondition:get_config_items()
    local all_status_ids = L{}
    for _, buff in pairs(res.buffs) do
        all_status_ids:append(buff.id)
    end

    local buffPickerConfigItem = MultiPickerConfigItem.new('status_ids', L{ self.status_id }, all_status_ids, function(status_ids)
        local text = localization_util.commas(status_ids:map(function(status_id) return StatusAilment.new(res.buffs[status_id].en):get_localized_name() end))
        return text
    end, "Status Effect Name")
    buffPickerConfigItem:setPickerTitle("Status Effects")
    buffPickerConfigItem:setPickerDescription("Choose a status effect.")
    buffPickerConfigItem:setPickerTextFormat(function(status_id)
        return i18n.resource('buffs', 'en', res.buffs[status_id].en)
    end)
    buffPickerConfigItem:setAllowsMultipleSelection(true)
    buffPickerConfigItem:setNumItemsRequired(1, 1)
    buffPickerConfigItem:setOnConfirm(function(status_ids)
        self.status_id = status_ids[1]
    end)

    return L{
        buffPickerConfigItem
    }
end

function HasStatusEffectCondition:tostring()
    return "Is "..i18n.resource_long('buffs', 'en', res.buffs[self.status_id].en)
end

function HasStatusEffectCondition.description()
    return "Has status effect."
end

function HasStatusEffectCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function HasStatusEffectCondition:serialize()
    return "HasStatusEffectCondition.new(" .. serializer_util.serialize_args(self.status_id) .. ")"
end

return HasStatusEffectCondition




