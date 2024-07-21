---------------------------
-- Condition checking whether the player has the given buffs.
-- @class module
-- @name HasBuffsCondition

local buff_util = require('cylibs/util/buff_util')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local GroupConfigItem = require('ui/settings/editors/config/GroupConfigItem')
local localization_util = require('cylibs/util/localization_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local HasBuffsCondition = setmetatable({}, { __index = Condition })
HasBuffsCondition.__index = HasBuffsCondition
HasBuffsCondition.__type = "HasBuffsCondition"
HasBuffsCondition.__class = "HasBuffsCondition"

function HasBuffsCondition.new(buff_names, num_required)
    local self = setmetatable(Condition.new(windower.ffxi.get_player().index), HasBuffsCondition)
    self.buff_names = buff_names or L{ "sleep" } -- save arg for serializer
    self.buff_ids = self.buff_names:map(function(buff_name) return buff_util.buff_id(buff_name)  end)
    self.num_required = num_required or self.buff_names:length()
    return self
end

function HasBuffsCondition.from_party_member(buff_names, num_required, party_member)
    local self = setmetatable(Condition.new(party_member:get_mob().index), HasBuffsCondition)
    self.buff_names = buff_names or L{} -- save arg for serializer
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

function HasBuffsCondition:get_config_items()
    local all_buffs = S(buff_util.get_all_buff_ids(true):map(function(buff_id)
        local buff = res.buffs[buff_id]
        if buff then
            return buff.en
        end
        return nil
    end):compact_map())
    all_buffs = L(all_buffs)
    all_buffs:append('None')
    all_buffs:sort()
    return L{
        GroupConfigItem.new('buff_names', L{
            PickerConfigItem.new('buff_name_1', self.buff_names[1] or 'None', all_buffs, function(buff_name)
                return buff_name:gsub("^%l", string.upper)
            end, "Buff 1"),
            PickerConfigItem.new('buff_name_2', self.buff_names[2] or 'None', all_buffs, function(buff_name)
                if buff_name then
                    return buff_name:gsub("^%l", string.upper)
                end
                return 'None'
            end, "Buff 2"),
            PickerConfigItem.new('buff_name_3', self.buff_names[3] or 'None', all_buffs, function(buff_name)
                if buff_name then
                    return buff_name:gsub("^%l", string.upper)
                end
                return 'None'
            end, "Buff 3")
        }, nil, "Buff Names"),
        ConfigItem.new('num_required', 1, 3, 1, nil, "Number Required")
    }
end

function HasBuffsCondition:tostring()
    local buff_names = self.buff_names or L{}
    return "Has "..self.num_required.."+ of "..localization_util.commas(buff_names)
end

function HasBuffsCondition.description()
    return "Has one or more buffs."
end

function HasBuffsCondition:serialize()
    return "HasBuffsCondition.new(" .. serializer_util.serialize_args(self.buff_names, self.num_required) .. ")"
end

return HasBuffsCondition




