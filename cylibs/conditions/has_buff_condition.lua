---------------------------
-- Condition checking whether the player or party member has a buff.
-- @class module
-- @name HasBuffCondition

local buff_util = require('cylibs/util/buff_util')
local party_util = require('cylibs/util/party_util')
local serializer_util = require('cylibs/util/serializer_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local StatusAilment = require('cylibs/battle/status_ailment')

local Condition = require('cylibs/conditions/condition')
local HasBuffCondition = setmetatable({}, { __index = Condition })
HasBuffCondition.__index = HasBuffCondition
HasBuffCondition.__type = "HasBuffCondition"
HasBuffCondition.__class = "HasBuffCondition"

function HasBuffCondition.new(buff_name, target_index)
    local self = setmetatable(Condition.new(target_index), HasBuffCondition)
    self.buff_name = buff_name or "Refresh"
    self.buff_id = buff_util.buff_id(self.buff_name)
    return self
end

function HasBuffCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(self:get_target_index() or target_index)
    if target then
        local all_buff_ids = buff_util.all_buff_ids(self.buff_name)
        local monster = player.party:get_target(target.id)
        if monster then
            for buff_id in all_buff_ids:it() do
                if monster:has_debuff(buff_id) then
                    return true
                end
            end
            return false
        else
            local party_member = player.alliance:get_alliance_member_named(target.name)
            if party_member:is_trust() then
                return S(party_member:get_buff_ids()):intersection(S(all_buff_ids)):length() > 0
            else
                -- need to make sure all debuff ids are added to buff_util before using this
                --local party_member = player.alliance:get_alliance_member_named(target.name)
                --return S(party_member:get_buff_ids()):contains(buff_id)
                return S(all_buff_ids):intersection(S(party_util.get_buffs(target.id))):length() > 0
            end
        end
    end
    return false
end

function HasBuffCondition:get_config_items()
    local all_buffs = L(S(L(buff_util.get_all_buff_ids(true):map(function(buff_id)
        local buff = res.buffs[buff_id]
        if buff then
            return buff.en
        end
        return nil
    end)):compact_map())):sort()

    return L{
        PickerConfigItem.new('buff_name', self.buff_name, all_buffs, function(buff_name)
            local buff = StatusAilment.new(buff_name)
            return buff:get_localized_name()
        end, "Buff Name")
    }
end

function HasBuffCondition:tostring()
    return "Is "..i18n.resource_long('buffs', 'en', self.buff_name)
end

function HasBuffCondition.description()
    return "Has buff."
end

function HasBuffCondition.valid_targets()
    return Condition.TargetType.AllTargets
end

function HasBuffCondition:serialize()
    return "HasBuffCondition.new(" .. serializer_util.serialize_args(self.buff_name) .. ")"
end

return HasBuffCondition




